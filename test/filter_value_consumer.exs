defmodule RabbitMQStreamTest.Consumer.FilterValue do
  use ExUnit.Case, async: false

  @moduletag :v3_13

  defmodule Conn1 do
    use RabbitMQStream.Connection
  end

  defmodule Producer do
    use RabbitMQStream.Producer,
      connection: Conn1,
      serializer: Jason

    @impl true
    def filter_value(message) do
      message["key"]
    end
  end

  defmodule Subs1 do
    use RabbitMQStream.Consumer,
      connection: Conn1,
      initial_offset: :next,
      stream_name: "filter-value-01",
      offset_tracking: [count: [store_after: 1]],
      properties: [filter: ["Subs1"]],
      serializer: Jason

    @impl true
    def handle_chunk(%{data_entries: [entry]}, %{private: parent}) do
      send(parent, {__MODULE__, entry})

      :ok
    end
  end

  defmodule Subs2 do
    use RabbitMQStream.Consumer,
      connection: Conn1,
      initial_offset: :next,
      stream_name: "filter-value-01",
      offset_tracking: [count: [store_after: 1]],
      properties: [filter: ["Subs2"]],
      serializer: Jason

    @impl true
    def handle_chunk(%{data_entries: [entry]}, %{private: parent}) do
      send(parent, {__MODULE__, entry})

      :ok
    end
  end

  defmodule Subs3 do
    use RabbitMQStream.Consumer,
      connection: Conn1,
      initial_offset: :next,
      stream_name: "filter-value-01",
      offset_tracking: [count: [store_after: 1]],
      properties: [match_unfiltered: true],
      serializer: Jason

    @impl true
    def handle_chunk(%{data_entries: [entry]}, %{private: parent}) do
      send(parent, {__MODULE__, entry})

      :ok
    end
  end

  test "should receive only the filtered messages" do
    {:ok, _} = Conn1.start_link()
    :ok = Conn1.connect()
    Conn1.delete_stream("filter-value-01")
    :ok = Conn1.create_stream("filter-value-01")
    {:ok, _} = Producer.start_link(stream_name: "filter-value-01")

    {:ok, _} = Subs1.start_link(private: self())
    {:ok, _} = Subs2.start_link(private: self())
    {:ok, _} = Subs3.start_link(private: self())

    message = %{"key" => "Subs1", "value" => "1"}
    :ok = Producer.publish(message)

    assert_receive {Subs1, ^message}, 500

    message = %{"key" => "Subs2", "value" => "2"}
    :ok = Producer.publish(message)
    assert_receive {Subs2, ^message}, 500

    message = %{"key" => "NO-FILTER-APPLIED", "value" => "3"}
    :ok = Producer.publish(message)
    assert_receive {Subs3, ^message}, 500
  end
end
