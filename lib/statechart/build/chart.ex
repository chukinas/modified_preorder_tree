defmodule Statechart.Build.Chart do
  alias Statechart.Chart
  alias Statechart.Chart.Query
  alias Statechart.Node
  alias Statechart.Metadata
  alias Statechart.Tree.IsTree

  #####################################
  # CONSTRUCTORS

  @spec fetch!(module(), pos_integer) :: Chart.t()
  def fetch!(module, line_number) do
    with true <- {:__statechart__, 0} in module.__info__(:functions),
         %Chart{} = chart <- module.__statechart__() do
      chart
    else
      _ ->
        raise StatechartError,
              "the module #{module} on line #{line_number} does not define a Statechart.Chart.t struct. See `use Statechart`"
    end
  end

  #####################################
  # CONVERTERS

  @spec fetch_node_by_metadata!(Chart.t(), Metadata.t()) :: Node.maybe_not_inserted()
  def fetch_node_by_metadata!(chart, metadata) do
    node =
      chart
      |> IsTree.fetch_nodes!()
      |> Enum.find(fn node -> Node.metadata(node) == metadata end)

    case node do
      %Node{} ->
        node

      _ ->
        raise StatechartError,
              "This should never happen, even with bad user input, but oh well - no matching node was found"
    end
  end

  def fetch_id_by_state!(chart, target_name) do
    case Query.fetch_id_by_state(chart, target_name) do
      {:ok, node_id} ->
        node_id

      {:error, _} ->
        raise StatechartError, "There is no node with name of #{inspect(target_name)}"
    end
  end

  def validate_target_id_is_descendent!(chart, origin_node_id, target_id) do
    case Query.validate_target_id_is_descendent(chart, origin_node_id, target_id) do
      :ok ->
        :ok

      {:error, :target_not_descendent} ->
        raise StatechartError, "default node must be a descendent"
    end
  end
end
