defmodule RabbitMQStream.Message.Data do
  @moduledoc false
  defmodule TuneData do
    @moduledoc false

    defstruct [
      :frame_max,
      :heartbeat
    ]
  end

  defmodule PeerPropertiesData do
    @moduledoc false

    defstruct [
      :peer_properties
    ]
  end

  defmodule SaslHandshakeData do
    @moduledoc false

    defstruct [
      :mechanisms
    ]
  end

  defmodule SaslAuthenticateData do
    @moduledoc false

    defstruct [
      :mechanism,
      :sasl_opaque_data
    ]
  end

  defmodule OpenData do
    @moduledoc false

    defstruct [
      :vhost,
      :connection_properties
    ]
  end

  defmodule HeartbeatData do
    @moduledoc false

    defstruct []
  end

  defmodule CloseData do
    @moduledoc false

    defstruct [
      :code,
      :reason
    ]
  end

  defmodule CreateData do
    @moduledoc false

    defstruct [
      :stream_name,
      :arguments
    ]
  end

  defmodule DeleteData do
    @moduledoc false

    defstruct [
      :stream_name
    ]
  end

  defmodule StoreOffsetData do
    @moduledoc false

    defstruct [
      :offset_reference,
      :stream_name,
      :offset
    ]
  end

  defmodule QueryOffsetData do
    @moduledoc false

    defstruct [
      :offset_reference,
      :stream_name,
      :offset
    ]
  end

  defmodule QueryMetadataData do
    @moduledoc false

    defstruct [
      :brokers,
      :streams
    ]
  end

  defmodule MetadataUpdateData do
    @moduledoc false

    defstruct [
      :stream_name
    ]
  end

  defmodule DeclarePublisherData do
    @moduledoc false

    defstruct [
      :id,
      :publisher_reference,
      :stream_name
    ]
  end

  defmodule DeletePublisherData do
    @moduledoc false

    defstruct [
      :publisher_id
    ]
  end

  defmodule BrokerData do
    @moduledoc false

    @type t :: %{
            reference: non_neg_integer(),
            host: String.t(),
            port: non_neg_integer()
          }

    defstruct [
      :reference,
      :host,
      :port
    ]
  end

  defmodule StreamData do
    @moduledoc false

    @type t :: %{
            code: non_neg_integer(),
            name: String.t(),
            leader: non_neg_integer(),
            replicas: [any()]
          }

    defstruct [
      :code,
      :name,
      :leader,
      :replicas
    ]
  end

  defmodule QueryPublisherSequenceData do
    @moduledoc false

    defstruct [
      :publisher_reference,
      :stream_name,
      :sequence
    ]
  end

  defmodule PublishData do
    @moduledoc false

    defstruct [
      :publisher_id,
      :published_messages
    ]
  end

  defmodule PublishErrorData do
    @moduledoc false

    defmodule Error do
      @moduledoc false

      defstruct [
        :publishing_id,
        :code
      ]
    end

    defstruct [
      :publisher_id,
      :errors
    ]
  end

  defmodule PublishConfirmData do
    @moduledoc false

    defstruct [
      :publisher_id,
      :publishing_ids
    ]
  end

  defmodule SubscribeRequestData do
    @moduledoc false

    @type t :: %{
            subscription_id: non_neg_integer(),
            stream_name: String.t(),
            offset: RabbitMQStream.Connection.offset(),
            credit: non_neg_integer(),
            properties: %{String.t() => String.t()}
          }

    defstruct [
      :subscription_id,
      :stream_name,
      :offset,
      :credit,
      :properties
    ]
  end

  defmodule UnsubscribeRequestData do
    @moduledoc false

    @type t :: %{
            subscription_id: non_neg_integer()
          }

    defstruct [
      :subscription_id
    ]
  end

  defmodule SubscribeResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule UnsubscribeResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule DeliverData do
    @moduledoc false
    @type t :: %{
            subscription_id: non_neg_integer(),
            osiris_chunk: nil
          }
    defstruct [
      :subscription_id,
      :osiris_chunk
    ]
  end

  def fetch_string(<<size::integer-size(16), text::binary-size(size), rest::binary>>) do
    {rest, to_string(text)}
  end

  def decode_array("", _) do
    {"", []}
  end

  def decode_array(<<0::integer-size(32), buffer::binary>>, _) do
    {buffer, []}
  end

  def decode_array(<<size::integer-size(32), buffer::binary>>, foo) do
    Enum.reduce(0..(size - 1), {buffer, []}, fn _, {buffer, acc} ->
      foo.(buffer, acc)
    end)
  end

  def decode_data(:close, ""), do: %CloseData{}
  def decode_data(:create_stream, ""), do: %CreateData{}
  def decode_data(:delete_stream, ""), do: %DeleteData{}
  def decode_data(:declare_publisher, ""), do: %DeclarePublisherData{}
  def decode_data(:delete_publisher, ""), do: %DeletePublisherData{}
  def decode_data(:subscribe, ""), do: %SubscribeResponseData{}
  def decode_data(:unsubscribe, ""), do: %UnsubscribeResponseData{}

  def decode_data(:query_offset, <<offset::unsigned-integer-size(64)>>) do
    %QueryOffsetData{offset: offset}
  end

  def decode_data(:query_publisher_sequence, <<sequence::unsigned-integer-size(64)>>) do
    %QueryPublisherSequenceData{sequence: sequence}
  end

  def decode_data(:peer_properties, buffer) do
    {"", peer_properties} =
      decode_array(buffer, fn buffer, acc ->
        {buffer, key} = fetch_string(buffer)
        {buffer, value} = fetch_string(buffer)

        {buffer, [{key, value} | acc]}
      end)

    %PeerPropertiesData{peer_properties: peer_properties}
  end

  def decode_data(:sasl_handshake, buffer) do
    {"", mechanisms} =
      decode_array(buffer, fn buffer, acc ->
        {buffer, value} = fetch_string(buffer)
        {buffer, [value | acc]}
      end)

    %SaslHandshakeData{mechanisms: mechanisms}
  end

  def decode_data(:sasl_authenticate, buffer) do
    %SaslAuthenticateData{sasl_opaque_data: buffer}
  end

  def decode_data(:tune, <<frame_max::unsigned-integer-size(32), heartbeat::unsigned-integer-size(32)>>) do
    %TuneData{frame_max: frame_max, heartbeat: heartbeat}
  end

  def decode_data(:open, buffer) do
    connection_properties =
      if buffer != "" do
        {"", connection_properties} =
          decode_array(buffer, fn buffer, acc ->
            {buffer, key} = fetch_string(buffer)
            {buffer, value} = fetch_string(buffer)

            {buffer, [{key, value} | acc]}
          end)

        Map.new(connection_properties)
      else
        []
      end

    %OpenData{connection_properties: connection_properties}
  end
end
