defmodule Statechart.Build.Tree do
  @moduledoc false
  # Functions for operating on the tree that are only used during the build steps
  # Many of these were extracted from Statechart.Tree

  alias Statechart.Node
  alias Statechart.Tree.IsTree

  #####################################
  # REDUCERS

  @spec update_node_by_id!(IsTree.t(), Node.id(), Node.reducer()) :: IsTree.t()
  def update_node_by_id!(tree, id, update_fn) do
    case tree
         |> IsTree.fetch_nodes!()
         |> _update_node_by_id([], id, update_fn) do
      {:ok, nodes} ->
        IsTree.put_nodes(tree, nodes)

      :error ->
        raise StatechartError,
              "This tree doesn't have that node, dummy!"
    end
  end

  @spec replace_node!(IsTree.t(), Node.t()) :: IsTree.t()
  def replace_node!(tree, node) do
    id = Node.id(node)
    update_fn = fn _node -> node end
    update_node_by_id!(tree, id, update_fn)
  end

  # Recursive function to find the given node
  @spec _update_node_by_id([Node.t()], [Node.t()], Node.id(), Node.reducer()) ::
          {:ok, [Node.t()]} | {:error, :id_not_found}
  defp _update_node_by_id([], _past_nodes, _id, _update_fn) do
    :error
  end

  defp _update_node_by_id([node | tail], past_nodes, id, update_fn) do
    case Node.id(node) do
      ^id ->
        nodes = [update_fn.(node) | tail]

        all_nodes =
          Enum.reduce(past_nodes, nodes, fn node, nodes ->
            [node | nodes]
          end)

        {:ok, all_nodes}

      _ ->
        _update_node_by_id(tail, [node | past_nodes], id, update_fn)
    end
  end
end
