defmodule RabbitMQStream.Connection.Handler do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      require Logger
      alias RabbitMQStream.{Message, Connection}
      alias RabbitMQStream.Message.{Encoder, Request, Response}
      alias RabbitMQStream.Connection.Helpers

      defp handle_message(%Connection{} = conn, %Request{command: :close} = request) do
        Logger.debug("Connection close requested by server: #{request.data.code} #{request.data.reason}")
        Logger.debug("Connection closed")

        %{conn | state: :closing}
        |> Helpers.push(:response, :close, correlation_id: request.correlation_id, code: :ok)
        |> handle_closed(request.data.reason)
      end

      defp handle_message(%Connection{} = conn, %Request{command: :tune} = request) do
        Logger.debug("Tunning complete. Starting heartbeat timer.")

        Process.send_after(self(), {:heartbeat}, conn.options[:heartbeat] * 1000)

        options = Keyword.merge(conn.options, frame_max: request.data.frame_max, heartbeat: request.data.heartbeat)

        %{conn | options: options, state: :opening}
        |> Helpers.push(:response, :tune, correlation_id: 0)
        |> Helpers.push(:request, :open)
      end

      defp handle_message(%Connection{} = conn, %Request{command: :heartbeat}) do
        conn
      end

      defp handle_message(%Connection{} = conn, %Request{command: :metadata_update} = request) do
        conn
        |> Helpers.push(:request, :query_metadata, streams: [request.data.stream_name])
      end

      defp handle_message(%Connection{} = conn, %Request{command: :deliver} = response) do
        pid = Map.get(conn.subscriptions, response.data.subscription_id)

        if pid != nil do
          send(pid, {:chunk, response.data.osiris_chunk})
        end

        conn
      end

      defp handle_message(%Connection{} = conn, %Request{command: command})
           when command in [:publish_confirm, :publish_error] do
        conn
      end

      defp handle_message(%Connection{} = conn, %Response{command: :close} = response) do
        Logger.debug("Connection closed: #{conn.options[:host]}:#{conn.options[:port]}")

        {{pid, _data}, conn} = Helpers.pop_request_tracker(conn, :close, response.correlation_id)

        conn = %{conn | state: :closed, socket: nil}

        GenServer.reply(pid, :ok)

        conn
      end

      defp handle_message(%Connection{} = conn, %Response{code: code})
           when code in [
                  :sasl_mechanism_not_supported,
                  :authentication_failure,
                  :sasl_error,
                  :sasl_challenge,
                  :sasl_authentication_failure_loopback,
                  :virtual_host_access_failure
                ] do
        Logger.error("Failed to connect to #{conn.options[:host]}:#{conn.options[:port]}. Reason: #{code}")

        for request <- conn.connect_requests do
          GenServer.reply(request, {:error, code})
        end

        %{conn | state: :closed, socket: nil, connect_requests: []}
      end

      defp handle_message(%Connection{} = conn, %Response{command: :credit, code: code})
           when code not in [:ok, nil] do
        Logger.error("Failed to credit subscription. Reason: #{code}")

        conn
      end

      defp handle_message(%Connection{} = conn, %Response{command: command, code: code} = response)
           when command in [
                  :create_stream,
                  :delete_stream,
                  :query_offset,
                  :declare_publisher,
                  :delete_publisher,
                  :subscribe,
                  :unsubscribe
                ] and
                  code not in [:ok, nil] do
        {{pid, _data}, conn} = Helpers.pop_request_tracker(conn, command, response.correlation_id)

        if pid != nil do
          GenServer.reply(pid, {:error, code})
        end

        conn
      end

      defp handle_message(%Connection{state: :closed} = conn, _) do
        Logger.error("Message received on a closed connection")

        conn
      end

      defp handle_message(%Connection{} = conn, %Response{command: :peer_properties} = response) do
        Logger.debug("Exchange successful.")
        Logger.debug("Initiating SASL handshake.")

        peer_properties =
          response.data.peer_properties
          |> Enum.map(fn
            {"version", value} ->
              version = value |> String.split(".") |> Enum.map(&String.to_integer/1)

              {"version", version}

            entry ->
              entry
          end)
          |> Map.new()

        %{conn | peer_properties: peer_properties}
        |> Helpers.push(:request, :sasl_handshake)
      end

      defp handle_message(%Connection{} = conn, %Response{command: :sasl_handshake} = response) do
        Logger.debug("SASL handshake successful. Initiating authentication.")

        %{conn | mechanisms: response.data.mechanisms}
        |> Helpers.push(:request, :sasl_authenticate)
      end

      defp handle_message(%Connection{} = conn, %Response{command: :sasl_authenticate, data: %{sasl_opaque_data: ""}}) do
        Logger.debug("Authentication successful. Initiating connection tuning.")

        conn
      end

      defp handle_message(%Connection{} = conn, %Response{command: :sasl_authenticate}) do
        Logger.debug("Authentication successful. Skipping connection tuning.")
        Logger.debug("Opening connection to vhost: \"#{conn.options[:vhost]}\"")

        conn
        |> Helpers.push(:request, :open)
        |> Map.put(:state, :opening)
      end

      defp handle_message(%Connection{} = conn, %Response{command: :tune} = response) do
        Logger.debug("Tunning data received. Starting heartbeat timer.")
        Logger.debug("Opening connection to vhost: \"#{conn.options[:vhost]}\"")

        options = Keyword.merge(conn.options, frame_max: response.data.frame_max, heartbeat: response.data.heartbeat)

        %{conn | options: options}
        |> Map.put(:state, :opening)
        |> Helpers.push(:request, :open)
      end

      defp handle_message(%Connection{} = conn, %Response{command: :open} = response) do
        Logger.debug("Successfully opened connection with vhost: \"#{conn.options[:vhost]}\"")

        for request <- conn.connect_requests do
          GenServer.reply(request, :ok)
        end

        send(self(), :flush_request_buffer)

        %{conn | state: :open, connect_requests: [], connection_properties: response.data.connection_properties}
      end

      defp handle_message(%Connection{} = conn, %Response{command: :query_metadata} = response) do
        {{pid, _data}, conn} = Helpers.pop_request_tracker(conn, :query_metadata, response.correlation_id)

        if pid != nil do
          GenServer.reply(pid, {:ok, response.data})
        end

        %{conn | streams: response.data.streams, brokers: response.data.brokers}
      end

      defp handle_message(%Connection{} = conn, %Response{command: :query_offset} = response) do
        {{pid, _data}, conn} = Helpers.pop_request_tracker(conn, :query_offset, response.correlation_id)

        if pid != nil do
          GenServer.reply(pid, {:ok, response.data.offset})
        end

        conn
      end

      defp handle_message(%Connection{} = conn, %Response{command: :declare_publisher} = response) do
        {{pid, id}, conn} = Helpers.pop_request_tracker(conn, :declare_publisher, response.correlation_id)

        if pid != nil do
          GenServer.reply(pid, {:ok, id})
        end

        conn
      end

      defp handle_message(%Connection{} = conn, %Response{command: :query_publisher_sequence} = response) do
        {{pid, _data}, conn} = Helpers.pop_request_tracker(conn, :query_publisher_sequence, response.correlation_id)

        if pid != nil do
          GenServer.reply(pid, {:ok, response.data.sequence})
        end

        conn
      end

      defp handle_message(%Connection{} = conn, %Response{command: :subscribe} = response) do
        {{pid, data}, conn} = Helpers.pop_request_tracker(conn, :subscribe, response.correlation_id)

        {subscription_id, subscriber} = data

        if pid != nil do
          GenServer.reply(pid, {:ok, subscription_id})
        end

        %{conn | subscriptions: Map.put(conn.subscriptions, subscription_id, subscriber)}
      end

      defp handle_message(%Connection{} = conn, %Response{command: :unsubscribe} = response) do
        {{pid, subscription_id}, conn} = Helpers.pop_request_tracker(conn, :unsubscribe, response.correlation_id)

        if pid != nil do
          GenServer.reply(pid, :ok)
        end

        %{conn | subscriptions: Map.drop(conn.subscriptions, [subscription_id])}
      end

      defp handle_message(%Connection{} = conn, %Response{command: command} = response)
           when command in [:create_stream, :delete_stream, :delete_publisher] do
        {{pid, _data}, conn} = Helpers.pop_request_tracker(conn, command, response.correlation_id)

        if pid != nil do
          GenServer.reply(pid, :ok)
        end

        conn
      end
    end
  end
end
