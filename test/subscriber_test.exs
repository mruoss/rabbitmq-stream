defmodule RabbitMQStreamTest.Subscriber do
  use ExUnit.Case, async: false
  alias RabbitMQStream.OsirisChunk
  require Logger

  defmodule SupervisedConnection do
    use RabbitMQStream.Connection
  end

  defmodule SupervisorPublisher do
    use RabbitMQStream.Publisher,
      connection: RabbitMQStreamTest.Subscriber.SupervisedConnection

    def before_start(_opts, state) do
      state.connection.create_stream(state.stream_name)

      state
    end
  end

  defmodule Subscriber do
    use RabbitMQStream.Subscriber,
      connection: RabbitMQStreamTest.Subscriber.SupervisedConnection

    @impl true
    def handle_chunk(%OsirisChunk{data_entries: entries}, %{private: parent}) do
      send(parent, {:handle_chunk, entries})

      :ok
    end
  end

  setup do
    {:ok, _conn} = SupervisedConnection.start_link(host: "localhost", vhost: "/")
    :ok = SupervisedConnection.connect()

    :ok
  end

  @stream "subscriber-test-stream-01"
  @reference_name "reference-01"
  test "should publish and receive a message" do
    {:ok, _publisher} = SupervisorPublisher.start_link(reference_name: @reference_name, stream_name: @stream)

    assert {:ok, subscription_id} = SupervisedConnection.subscribe(@stream, self(), :next, 999)

    message = inspect(%{message: "Hello, world2!"})

    SupervisorPublisher.publish(message)

    assert_receive {:chunk, %OsirisChunk{data_entries: [^message]}}, 500

    assert :ok = SupervisedConnection.unsubscribe(subscription_id)

    SupervisorPublisher.publish(message)

    refute_receive {:chunk, %OsirisChunk{}}, 500
    SupervisedConnection.delete_stream(@stream)
  end

  @stream "subscriber-test-stream-02"
  @reference_name "reference-02"
  test "should credit a subscriber" do
    {:ok, _publisher} = SupervisorPublisher.start_link(reference_name: @reference_name, stream_name: @stream)

    assert {:ok, subscription_id} = SupervisedConnection.subscribe(@stream, self(), :next, 1)

    message = inspect(%{message: "Hello, world1!"})

    SupervisorPublisher.publish(message)

    assert_receive {:chunk, %OsirisChunk{data_entries: [^message]}}, 500

    message = inspect(%{message: "Hello, world2!"})

    SupervisorPublisher.publish(message)

    refute_receive {:chunk, %OsirisChunk{}}, 500

    assert :ok = SupervisedConnection.credit(subscription_id, 1)

    assert_receive {:chunk, %OsirisChunk{data_entries: [^message]}}, 500
    SupervisedConnection.delete_stream(@stream)
  end

  @stream "subscriber-test-stream-10"
  @reference_name "reference-10"
  test "a message should be received by a persistent subscriber" do
    {:ok, _publisher} =
      SupervisorPublisher.start_link(reference_name: @reference_name, stream_name: @stream)

    {:ok, _subscriber} =
      Subscriber.start_link(
        initial_offset: :first,
        stream_name: @stream,
        private: self()
      )

    message1 = "Subscriber Test: 1"

    SupervisorPublisher.publish(message1)
    assert_receive {:handle_chunk, [^message1]}, 500

    SupervisedConnection.delete_stream(@stream)
  end
end
