defmodule RabbitMQStream.Message.Types do
  @moduledoc false
  alias RabbitMQStream.Message.Helpers

  defmodule TuneData do
    @moduledoc false
    @enforce_keys [:frame_max, :heartbeat]
    @type t :: %{
            frame_max: non_neg_integer(),
            heartbeat: non_neg_integer()
          }

    defstruct [
      :frame_max,
      :heartbeat
    ]
  end

  defmodule PeerPropertiesData do
    @moduledoc false
    @enforce_keys [:peer_properties]
    @type t :: %{peer_properties: [[String.t()]]}

    defstruct [:peer_properties]
  end

  defmodule SaslHandshakeData do
    @moduledoc false

    @type t :: %{mechanisms: [String.t()]}

    defstruct [:mechanisms]
  end

  defmodule SaslAuthenticateData do
    @moduledoc false
    @type t :: %{
            mechanism: String.t(),
            sasl_opaque_data: Keyword.t()
          }

    defstruct [
      :mechanism,
      :sasl_opaque_data
    ]
  end

  defmodule OpenRequestData do
    @moduledoc false
    @enforce_keys [:vhost]
    @type t :: %{
            vhost: String.t()
          }

    defstruct [
      :vhost
    ]
  end

  defmodule OpenResponseData do
    @moduledoc false
    @enforce_keys [:connection_properties]
    @type t :: %{connection_properties: Keyword.t()}
    defstruct [:connection_properties]
  end

  defmodule HeartbeatData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule CloseRequestData do
    @moduledoc false
    @enforce_keys [:code, :reason]

    @type t :: %{
            code: RabbitMQStream.Message.Helpers.code(),
            reason: String.t()
          }
    defstruct [:code, :reason]
  end

  defmodule CloseResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule CreateStreamRequestData do
    @moduledoc false
    @enforce_keys [:stream_name, :arguments]
    @type t :: %{
            stream_name: String.t(),
            arguments: Keyword.t()
          }

    defstruct [:stream_name, :arguments]
  end

  defmodule CreateStreamResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule DeleteStreamRequestData do
    @moduledoc false
    @enforce_keys [:stream_name]
    @type t :: %{stream_name: String.t()}
    defstruct [:stream_name]
  end

  defmodule DeleteStreamResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule StoreOffsetRequestData do
    @moduledoc false

    @enforce_keys [:stream_name, :offset_reference, :offset]
    @type t :: %{
            stream_name: String.t(),
            offset_reference: String.t(),
            offset: non_neg_integer()
          }

    defstruct [
      :offset_reference,
      :stream_name,
      :offset
    ]
  end

  defmodule StoreOffsetResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule QueryOffsetRequestData do
    @moduledoc false
    @enforce_keys [:stream_name, :offset_reference]
    @type t :: %{
            stream_name: String.t(),
            offset_reference: String.t()
          }

    defstruct [:offset_reference, :stream_name]
  end

  defmodule QueryOffsetResponseData do
    @moduledoc false

    @enforce_keys [:offset]
    @type t :: %{offset: non_neg_integer()}
    defstruct [:offset]
  end

  defmodule QueryMetadataRequestData do
    @moduledoc false
    @enforce_keys [:streams]
    @type t :: %{offset: [String.t()]}
    defstruct [:streams]
  end

  defmodule QueryMetadataResponseData do
    @moduledoc false
    @type t :: %{
            streams: [StreamData.t()],
            brokers: [BrokerData.t()]
          }

    defstruct [:streams, :brokers]

    defmodule BrokerData do
      @moduledoc false
      @enforce_keys [:reference, :host, :port]
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
      @enforce_keys [:code, :name, :leader, :replicas]
      @type t :: %{
              code: RabbitMQStream.Message.Helpers.code(),
              name: String.t(),
              leader: non_neg_integer(),
              replicas: [non_neg_integer()]
            }

      defstruct [
        :code,
        :name,
        :leader,
        :replicas
      ]
    end
  end

  defmodule MetadataUpdateData do
    @moduledoc false
    @enforce_keys [:stream_name, :code]
    @type t :: %{
            stream_name: String.t(),
            code: non_neg_integer()
          }
    defstruct [:stream_name, :code]
  end

  defmodule DeclareProducerRequestData do
    @moduledoc false
    @enforce_keys [:id, :producer_reference, :stream_name]
    @type t :: %{
            id: non_neg_integer(),
            producer_reference: String.t(),
            stream_name: String.t()
          }

    defstruct [
      :id,
      :producer_reference,
      :stream_name
    ]
  end

  defmodule DeclareProducerResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule DeleteProducerRequestData do
    @moduledoc false
    @enforce_keys [:producer_id]
    @type t :: %{producer_id: non_neg_integer()}
    defstruct [:producer_id]
  end

  defmodule DeleteProducerResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule QueryProducerSequenceRequestData do
    @moduledoc false
    @enforce_keys [:producer_reference, :stream_name]
    @type t :: %{
            producer_reference: String.t(),
            stream_name: String.t()
          }

    defstruct [:producer_reference, :stream_name]
  end

  defmodule QueryProducerSequenceResponseData do
    @moduledoc false
    @enforce_keys [:sequence]
    @type t :: %{sequence: non_neg_integer()}
    defstruct [:sequence]
  end

  defmodule PublishData do
    @moduledoc false
    @enforce_keys [:producer_id, :messages]
    @type t :: %{
            producer_id: non_neg_integer(),
            messages: [{publishing_id :: non_neg_integer(), message :: binary(), filter_value :: binary() | nil}]
          }

    defstruct [:producer_id, :messages]
  end

  defmodule PublishErrorData do
    @moduledoc false
    @enforce_keys [:producer_id, :errors]
    @type t :: %{
            producer_id: non_neg_integer(),
            errors: [Error.t()]
          }
    defstruct [:producer_id, :errors]

    defmodule Error do
      @moduledoc false
      @enforce_keys [:publishing_id, :code]
      @type t :: %{
              publishing_id: non_neg_integer(),
              code: RabbitMQStream.Message.Helpers.code()
            }

      defstruct [:publishing_id, :code]
    end
  end

  defmodule PublishConfirmData do
    @moduledoc false
    @enforce_keys [:producer_id, :publishing_ids]
    @type t :: %{
            producer_id: non_neg_integer(),
            publishing_ids: [non_neg_integer()]
          }
    defstruct [:producer_id, :publishing_ids]
  end

  defmodule SubscribeRequestData do
    @moduledoc """
    Supported properties:

    * `single-active-consumer`: set to `true` to enable [single active consumer](https://blog.rabbitmq.com/posts/2022/07/rabbitmq-3-11-feature-preview-single-active-consumer-for-streams/) for this subscription.
    * `super-stream`: set to the name of the super stream the subscribed is a partition of.
    * `filter.` (e.g. `filter.0`, `filter.1`, etc): prefix to use to define filter values for the subscription.
    * `match-unfiltered`: whether to return messages without any filter value or not.
    """

    defstruct [
      :subscription_id,
      :stream_name,
      :offset,
      :credit,
      :properties
    ]

    @type t :: %{
            subscription_id: non_neg_integer(),
            stream_name: String.t(),
            offset: RabbitMQStream.Connection.offset(),
            credit: non_neg_integer(),
            properties: [property()]
          }

    @type property ::
            {:single_active_consumer, String.t()}
            | {:super_stream, String.t()}
            | {:filter, [String.t()]}
            | {:match_unfiltered, boolean()}

    def new!(opts) do
      %__MODULE__{
        credit: opts[:credit],
        offset: opts[:offset],
        properties: opts[:properties],
        stream_name: opts[:stream_name],
        subscription_id: opts[:subscription_id]
      }
    end
  end

  defmodule ConsumerUpdateRequestData do
    @moduledoc false
    @enforce_keys [:subscription_id, :active]

    @type t :: %{
            subscription_id: non_neg_integer(),
            active: boolean()
          }

    defstruct [:subscription_id, :active]
  end

  defmodule ConsumerUpdateResponseData do
    @moduledoc false
    @enforce_keys [:offset]
    @type t :: %{offset: RabbitMQStream.Connection.offset()}
    defstruct [:offset]
  end

  defmodule UnsubscribeRequestData do
    @moduledoc false
    @enforce_keys [:subscription_id]
    @type t :: %{subscription_id: non_neg_integer()}
    defstruct [:subscription_id]
  end

  defmodule CreditRequestData do
    @moduledoc false
    @enforce_keys [:subscription_id, :credit]
    @type t :: %{
            subscription_id: non_neg_integer(),
            credit: non_neg_integer()
          }
    defstruct [:subscription_id, :credit]
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

  defmodule CreditResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule RouteRequestData do
    @moduledoc false
    @enforce_keys [:routing_key, :super_stream]
    @type t :: %{
            routing_key: String.t(),
            super_stream: String.t()
          }
    defstruct [:routing_key, :super_stream]
  end

  defmodule RouteResponseData do
    @moduledoc false
    @enforce_keys [:streams]
    @type t :: %{streams: [String.t()]}
    defstruct [:streams]
  end

  defmodule PartitionsQueryRequestData do
    @moduledoc false
    @enforce_keys [:super_stream]
    @type t :: %{super_stream: String.t()}
    defstruct [:super_stream]
  end

  defmodule PartitionsQueryResponseData do
    @moduledoc false
    @enforce_keys [:streams]
    @type t :: %{streams: [String.t()]}
    defstruct [:streams]
  end

  defmodule DeliverData do
    @moduledoc false
    @enforce_keys [:subscription_id, :osiris_chunk]
    @type t :: %{
            committed_offset: non_neg_integer() | nil,
            subscription_id: non_neg_integer(),
            osiris_chunk: RabbitMQStream.OsirisChunk.t()
          }
    defstruct [
      :committed_offset,
      :subscription_id,
      :osiris_chunk
    ]
  end

  defmodule ExchangeCommandVersionsData do
    @moduledoc false
    @enforce_keys [:commands]
    @type t :: %{commands: [Command.t()]}
    defstruct [:commands]

    defmodule Command do
      @moduledoc false
      @enforce_keys [:key, :min_version, :max_version]
      @type t :: %{
              key: Helpers.command(),
              min_version: non_neg_integer(),
              max_version: non_neg_integer()
            }
      defstruct [:key, :min_version, :max_version]
    end

    def new!(_opts \\ []) do
      %__MODULE__{
        commands: [
          %Command{key: :publish, min_version: 1, max_version: 2},
          %Command{key: :deliver, min_version: 1, max_version: 2},
          %Command{key: :declare_producer, min_version: 1, max_version: 1},
          %Command{key: :publish_confirm, min_version: 1, max_version: 1},
          %Command{key: :publish_error, min_version: 1, max_version: 1},
          %Command{key: :query_producer_sequence, min_version: 1, max_version: 1},
          %Command{key: :delete_producer, min_version: 1, max_version: 1},
          %Command{key: :subscribe, min_version: 1, max_version: 1},
          %Command{key: :credit, min_version: 1, max_version: 1},
          %Command{key: :store_offset, min_version: 1, max_version: 1},
          %Command{key: :query_offset, min_version: 1, max_version: 1},
          %Command{key: :unsubscribe, min_version: 1, max_version: 1},
          %Command{key: :create_stream, min_version: 1, max_version: 1},
          %Command{key: :delete_stream, min_version: 1, max_version: 1},
          %Command{key: :query_metadata, min_version: 1, max_version: 1},
          %Command{key: :metadata_update, min_version: 1, max_version: 1},
          %Command{key: :peer_properties, min_version: 1, max_version: 1},
          %Command{key: :sasl_handshake, min_version: 1, max_version: 1},
          %Command{key: :sasl_authenticate, min_version: 1, max_version: 1},
          %Command{key: :tune, min_version: 1, max_version: 1},
          %Command{key: :open, min_version: 1, max_version: 1},
          %Command{key: :close, min_version: 1, max_version: 1},
          %Command{key: :heartbeat, min_version: 1, max_version: 1},
          %Command{key: :route, min_version: 1, max_version: 1},
          %Command{key: :partitions, min_version: 1, max_version: 1},
          %Command{key: :consumer_update, min_version: 1, max_version: 1},
          %Command{key: :exchange_command_versions, min_version: 1, max_version: 1},
          %Command{key: :stream_stats, min_version: 1, max_version: 1},
          %Command{key: :create_super_stream, min_version: 1, max_version: 1},
          %Command{key: :delete_super_stream, min_version: 1, max_version: 1}
        ]
      }
    end
  end

  defmodule StreamStatsRequestData do
    @moduledoc false
    @enforce_keys [:stream_name]
    @type t :: %{stream_name: String.t()}
    defstruct [:stream_name]
  end

  defmodule StreamStatsResponseData do
    @enforce_keys [:stats]
    @type t :: %{stats: %{String.t() => integer()}}
    defstruct [:stats]
  end

  defmodule CreateSuperStreamRequestData do
    @enforce_keys [:name, :partitions, :arguments]
    @type t :: %{
            name: String.t(),
            partitions: [{String.t(), String.t()}],
            arguments: Keyword.t(String.t())
          }
    defstruct [:name, :partitions, :arguments]
  end

  defmodule CreateSuperStreamResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end

  defmodule DeleteSuperStreamRequestData do
    @moduledoc false
    @enforce_keys [:name]
    @type t :: %{name: String.t()}
    defstruct [:name]
  end

  defmodule DeleteSuperStreamResponseData do
    @moduledoc false
    @type t :: %{}
    defstruct []
  end
end
