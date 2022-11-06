defmodule MPTree.TestSupport.Generator do
  @moduledoc false

  import StreamData
  alias MPTree.Node
  alias MPTree.TestSupport.MyNode

  @min_starting_id 1

  # => MPTree.t()
  def tree do
    map(_nodes(), &build_tree/1)
  end

  # => [MyNode.t()]
  defp _nodes do
    map(uniq_list_of(atom(:alphanumeric)), fn names ->
      Enum.with_index(names, fn name, index ->
        max_parent_id = index + @min_starting_id
        rand_parent_id = Enum.random(@min_starting_id..max_parent_id)
        MyNode.new(name, rand_parent_id)
      end)
    end)
  end

  # [MyNode.t()] => MPTree.t()
  defp build_tree(nodes) do
    starting_tree = MyNode.root() |> MPTree.from_node()

    Enum.reduce(nodes, starting_tree, fn node, tree ->
      parent_match_fn = match_by_id(node.parent_id)
      {:ok, tree} = MPTree.insert(tree, node, parent_match_fn)
      tree
    end)
  end

  defp match_by_id(id) do
    &(Node.__id__(&1) == id)
  end
end
