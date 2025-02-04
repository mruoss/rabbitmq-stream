defmodule RabbitMQStream.SuperConsumer.Manager do
  @moduledoc false
  alias RabbitMQStream.SuperConsumer

  use GenServer

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts \\ []) do
    state = struct(SuperConsumer, opts)

    {:ok, state, {:continue, :start}}
  end

  @impl true
  def handle_continue(:start, %SuperConsumer{} = state) do
    for partition <- 0..(state.partitions - 1) do
      {:ok, _pid} =
        DynamicSupervisor.start_child(
          state.dynamic_supervisor,
          {
            RabbitMQStream.Consumer,
            Keyword.merge(state.consumer_opts,
              name: {:via, Registry, {state.registry, partition}},
              stream_name: "#{state.super_stream}-#{partition}",
              consumer_module: state.consumer_module,
              properties: [
                single_active_consumer: true,
                super_stream: state.super_stream
              ]
            )
          }
        )
    end

    {:noreply, state, :hibernate}
  end
end
