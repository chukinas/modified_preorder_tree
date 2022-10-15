defmodule Statechart.Build.MacroSubchart do
  @moduledoc false
  # This module does the heavy lifting for the `Statechart.subchart` macro.

  require Statechart.Node, as: Node
  alias __MODULE__
  alias Statechart.Build
  alias Statechart.Build.Acc
  alias Statechart.Build.Chart, as: BuildChart
  alias Statechart.Build.MacroState
  alias Statechart.Build.Tree, as: BuildTree
  alias Statechart.Chart
  alias Statechart.HasIdRefs
  alias Statechart.Metadata
  alias Statechart.Tree

  def build_ast(name, module, do_block) do
    quote do
      MacroSubchart.__on_enter__(@__sc_build_step__, __ENV__, unquote(name), unquote(module))
      unquote(do_block)
      Acc.pop_id!(__ENV__)
    end
  end

  @spec __on_enter__(Build.build_step(), Macro.Env.t(), Node.name(), module()) :: :ok
  def __on_enter__(:insert_nodes = _build_step, env, name, _module) do
    MacroState.insert_node(env, name)
  end

  def __on_enter__(:insert_subcharts, env, _name, subchart_module) do
    meta = Metadata.from_env(env)
    chart = Acc.chart(env)
    root_node = BuildChart.fetch_node_by_metadata!(chart, meta)

    with subchart <- BuildChart.fetch!(subchart_module, Metadata.line(meta)),
         {:ok, new_chart} <- merge_subchart_at(chart, subchart, Node.id(root_node)) do
      Acc.put_chart(env, new_chart)
      Build.__push_current_id__(env)
    end

    :ok
  end

  def __on_enter__(_build_step, env, _name, _module) do
    Build.__push_current_id__(env)
  end

  # TODO test that calling state/1,2 inside subchart raises

  @spec merge_subchart_at(Chart.t(), Chart.t(), Node.id()) ::
          {:ok, Chart.t()} | {:error, :id_not_found}
  defp merge_subchart_at(chart, subchart, merge_node_id) do
    subchart_root = Tree.root(subchart)
    subchart_root_id = Node.id(subchart_root)

    # TODO remove these first two from with
    with {:ok, subchart_descendents} = Tree.fetch_descendents_by_id(subchart, subchart_root_id),
         chart =
           BuildTree.update_node_by_id!(chart, merge_node_id, &Node.merge(&1, subchart_root)),
         {:ok, merge_node} <- Tree.fetch_node_by_id(chart, merge_node_id) do
      parent_rgt = Node.rgt(merge_node)

      new_nodes =
        (fn ->
           old_nodes_addend_lft_rgt = 2 * length(subchart_descendents)
           # TODO DRY some of this out
           maybe_update_old_node = fn %Node{} = node, key ->
             Node.update_if(node, key, &(&1 >= parent_rgt), &(&1 + old_nodes_addend_lft_rgt))
           end

           chart
           |> Tree.fetch_nodes!()
           |> Stream.map(&maybe_update_old_node.(&1, :lft))
           |> Stream.map(&maybe_update_old_node.(&1, :rgt))
         end).()

      new_descendents =
        case subchart_descendents do
          [] ->
            []

          [first_descendent | _tail] ->
            descendents_lft_rgt_addend = parent_rgt - Node.lft(first_descendent)

            # TODO isn't there a better way?
            descendents_min_id = Enum.min_by(subchart_descendents, &Node.id/1) |> Node.id()

            starting_new_id = 1 + Tree.max_node_id(chart)
            descendents_id_addend = starting_new_id - descendents_min_id

            new_nodes_id_update = fn
              ^subchart_root_id -> merge_node_id
              id when is_integer(id) -> id + descendents_id_addend
            end

            Enum.map(subchart_descendents, fn %Node{} = node ->
              node
              |> Node.add_to_lft_rgt(descendents_lft_rgt_addend)
              |> HasIdRefs.update_id_refs(new_nodes_id_update)
            end)
        end

      nodes =
        [new_nodes, new_descendents]
        |> Stream.concat()
        |> Enum.sort_by(&Node.lft/1)

      {:ok, Tree.put_nodes(chart, nodes)}
    else
      {:error, reason} -> {:error, reason}
    end
  end
end
