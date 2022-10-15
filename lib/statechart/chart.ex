defmodule Statechart.Chart do
  @moduledoc false

  use Statechart.Util.GetterStruct
  alias Statechart.Node
  alias Statechart.Tree
  alias Statechart.Tree.IsTree
  alias Statechart.Metadata
  alias Statechart.Metadata.HasMetadata

  #####################################
  # TYPES

  @starting_node_id Tree.starting_node_id()

  @type spec :: t() | module

  getter_struct do
    field :nodes, [Node.t(), ...], default: [Node.root(@starting_node_id)]
  end

  #####################################
  # CONSTRUCTORS

  @spec new() :: t
  def new() do
    %__MODULE__{nodes: [Node.root(@starting_node_id)]}
  end

  # TODO Chart shouldn't know about how this was built
  def from_env(env) do
    %__MODULE__{
      nodes: [Node.root(@starting_node_id, metadata: Metadata.from_env(env))]
    }
  end

  #####################################
  # IMPLEMENTATIONS

  defimpl IsTree do
    alias Statechart.Chart

    def put_nodes(chart, nodes) do
      struct!(chart, nodes: nodes)
    end

    defdelegate fetch_nodes!(chart), to: Chart, as: :nodes
  end

  defimpl HasMetadata do
    # A tree's metadata is the metadata of its root node

    def fetch(chart) do
      chart
      |> Tree.root()
      |> HasMetadata.fetch()
    end
  end

  # defimpl Inspect do
  #   def inspect(chart, opts) do
  #     Util.Inspect.custom_kv("Statechart", chart.nodes, opts)
  #   end
  # end
end
