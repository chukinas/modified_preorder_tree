defmodule MPTree do
  @external_resource "README.md"
  [_ignored_intro, usage_section, _ignored] =
    "README.md" |> File.read!() |> String.split(~r/<!---.*moduledoc.*-->/, parts: 3)

  @moduledoc usage_section

  # Here are some words about Modifield Preorder Tree Traversal.
  # - ancestors: the `t:path/0` list minus the last node
  # - parent: the parent of the node in question
  # - children: ancestors, but only one level deep
  # See https://gist.github.com/tmilos/f2f999b5839e2d42d751
  #
  # DESCENDENTS
  #
  # All the nodes that have a given node as an ancestor.

  # In Modified Preorder Tree lingo,
  # a descendent has an `lft` greater that its ancestor
  # and a `rgt` less that its ancestor.

  use TypedStruct
  alias MPTree.Node
  alias MPTree.NodeMeta
  alias MPTree.Seeker

  defmacrop extract_value!(ok_tuple_or_error, error_msg \\ "failed match") do
    quote do
      case unquote(ok_tuple_or_error) do
        {:ok, val} -> val
        :error -> raise "MPTree: #{unquote(error_msg)}"
      end
    end
  end

  #####################################
  # TYPES

  @typedoc """
  Used by `insert`, `update`, and `fetch` functions to find nodes.

  Beware, this will match only the first node it finds.
  If there any many nodes that might possibly pass the test,
  the results could be unpredictable.
  """
  @type match_fn :: (Node.t() -> as_boolean(any))

  @typedoc """
  Updates a node
  """
  @type update_fn :: (Node.t() -> Node.t())

  @type nodes :: [Node.t()]
  @type transition_path :: [{:exit | :enter, Node.t()}]

  typedstruct enforce: true do
    field :nodes, [Node.t(), ...]
  end

  #####################################
  # CONSTRUCTORS

  @doc """
  Create a tree from a [`root_node`](`MPTree.Node`).
  """
  @spec from_node(Node.t()) :: t()
  def from_node(%{__mptree_meta__: %NodeMeta{}} = root_node) do
    node_with_default_meta = Map.replace!(root_node, :__mptree_meta__, NodeMeta.new())
    %__MODULE__{nodes: [node_with_default_meta]}
  end

  #####################################
  # REDUCERS

  @doc """
  Insert a node or tree as a new child of the node matching `parent_fn`.

  In this example, the green node is about to be inserted.
  ![before insertion](assets/tree_insert_before.svg)

  Here is after the insertion.

  ![after insertion](assets/tree_insert_after.svg)

  Returns `:error` if no existing node matches [`parent_fn`](`t:match_fn/0`)
  """
  @spec insert(t(), Node.t() | t(), match_fn()) :: {:ok, t()} | :error
  def insert(tree, node_or_tree, parent_fn)

  def insert(%__MODULE__{} = tree, %{__mptree_meta__: %NodeMeta{}} = node, parent_fn)
      when is_function(parent_fn, 1) do
    subtree = from_node(node)
    insert(tree, subtree, parent_fn)
  end

  def insert(
        %__MODULE__{nodes: old_nodes} = tree,
        %__MODULE__{nodes: new_nodes},
        parent_fn
      )
      when is_function(parent_fn, 1) do
    subtree_starting_id = 1 + __max_node_id__(tree)
    old_nodes_addend = 2 * length(new_nodes)

    with {:ok, [parent]} <- Seeker.filter(old_nodes, parent_fn, keep: [:matched]) do
      parent_rgt = Node.__rgt__(parent)
      new_nodes_addend = parent_rgt

      incremented_old_nodes =
        Stream.map(old_nodes, &Node.__incr_lft_rgt__(&1, old_nodes_addend, parent_rgt))

      incremented_new_nodes =
        new_nodes
        |> Stream.map(&Node.__incr_lft_rgt__(&1, new_nodes_addend))
        |> Stream.map(&Node.__incr_id__(&1, subtree_starting_id - 1))

      nodes =
        [incremented_old_nodes, incremented_new_nodes]
        |> Stream.concat()
        |> Enum.sort_by(&Node.__lft__/1)

      {:ok, %__MODULE__{tree | nodes: nodes}}
    end
  end

  @doc """
  Insert a node or tree as a new child of the node matching `parent_fn`.

  Throws if no existing node matches [`parent_fn`](`t:match_fn/0`)
  """
  @spec insert!(t(), Node.t() | t(), match_fn()) :: t()
  def insert!(tree, node_or_tree, parent_fn) when is_function(parent_fn, 1) do
    insert(tree, node_or_tree, parent_fn) |> extract_value!
  end

  @doc """
  Apply `t:update_fn/0` to all nodes.
  """
  @spec update_nodes(t(), update_fn()) :: t()
  def update_nodes(%__MODULE__{nodes: nodes} = tree, update_fn) when is_function(update_fn, 1) do
    %__MODULE__{tree | nodes: Enum.map(nodes, update_fn)}
  end

  @doc """
  Apply `t:update_fn/0` to all nodes matching the `t:match_fn/0`.
  """
  @spec update_nodes(t(), update_fn(), match_fn()) :: t()
  def update_nodes(tree, update_fn, match_fn)
      when is_function(update_fn, 1) and is_function(match_fn, 1) do
    update_nodes(tree, fn node ->
      if match_fn.(node), do: update_fn.(node), else: node
    end)
  end

  #####################################
  # CONVERTERS

  @doc """
  Return ancestors of and the node itself matching `descendent_fn`.

  In this example, the blue (ancestor) and red (matched) nodes are returned.
  ![ancestors and self](assets/tree_ancestors.svg)

  Returns `:error` if no node is found.
  """
  @spec fetch_ancestors_and_self(t, MPTree.match_fn()) :: {:ok, nodes()} | :error
  def fetch_ancestors_and_self(tree, descendent_fn) do
    with {:ok, node} <- fetch_node(tree, descendent_fn) do
      ancestors =
        tree
        |> MPTree.nodes()
        |> Enum.filter(&Node.__ancestor_and_descendent__?(&1, node))

      {:ok, ancestors ++ [node]}
    end
  end

  @doc """
  Return ancestors of and the node itself matching `descendent_fn`.

  Throws if no node is found.
  """
  @spec fetch_ancestors_and_self!(t, MPTree.match_fn()) :: nodes()
  def fetch_ancestors_and_self!(tree, descendent_fn) do
    fetch_ancestors_and_self(tree, descendent_fn) |> extract_value!
  end

  @doc """
  Find children of the node matching `parent_fn`

  In this example, the red node matches, and the blue nodes are returned
  ```elixir
  [
    b,
    e
  ]
  ```

  ![fetch_children](assets/tree_children.svg)

  Returns `:error` if no parent is found.
  """
  @spec fetch_children(t(), match_fn) :: {:ok, [Node.t()]} | :error
  def fetch_children(%__MODULE__{nodes: nodes} = _tree, parent_fn)
      when is_function(parent_fn, 1) do
    with {:ok, [parent | tail]} <- Seeker.filter(nodes, parent_fn, keep: [:matched, :descendents]) do
      if Node.__leaf__?(parent) do
        {:ok, []}
      else
        {:ok, _children_from_tail(tail, parent)}
      end
    end
  end

  @doc """
  Find children of the node matching `parent_fn`.

  Throws if no parent is found.
  """
  @spec fetch_children!(t(), match_fn()) :: [Node.t()]
  def fetch_children!(%__MODULE__{} = tree, parent_fn) when is_function(parent_fn, 1) do
    fetch_children(tree, parent_fn) |> extract_value!("no node matching #{inspect(parent_fn)}")
  end

  @doc """
  Find descendents of the node matching `ancestor_fn`.

  In this example, diagram, the blue (descendent) nodes are returned.
  The red (matched) node is not returned.

  ![descendents](assets/tree_descendents.svg)

  Returns `:error` if no ancestor is found.
  """
  @spec fetch_descendents(t(), match_fn()) :: {:ok, [Node.t()]} | :error
  def fetch_descendents(%__MODULE__{nodes: nodes} = _tree, ancestor_fn)
      when is_function(ancestor_fn, 1) do
    Seeker.filter(nodes, ancestor_fn, keep: [:descendents])
  end

  @doc """
  Find descendents of the node matching `ancestor_fn`.

  Throws if no ancestor is found.
  """
  @spec fetch_descendents!(t(), match_fn()) :: [Node.t()]
  def fetch_descendents!(%__MODULE__{} = tree, ancestor_fn) when is_function(ancestor_fn, 1) do
    fetch_descendents(tree, ancestor_fn) |> extract_value!
  end

  @doc """
  Find all ancestors and descendents of the node matching `match_fn`.

  In the below diagram, the red (matched node) and blue (ancestor and descendent) nodes are returned.

  ![family tree](assets/tree_family_tree.svg)

  Returns `:error` if node is not found.
  """
  @spec fetch_family_tree(t(), MPTree.match_fn()) :: {:ok, nodes()} | :error
  def fetch_family_tree(%__MODULE__{nodes: nodes}, match_fn) when is_function(match_fn, 1) do
    Seeker.filter(nodes, match_fn)
  end

  @doc """
  Find all ancestors and descendents of the node matching `match_fn`.

  Throws if node is not found.
  """
  @spec fetch_family_tree!(t(), MPTree.match_fn()) :: nodes()
  def fetch_family_tree!(tree, match_fn) do
    fetch_family_tree(tree, match_fn) |> extract_value!()
  end

  @doc """
  Return the first node matching `match_fn`.

  In this example, the red and blue nodes would all match, but only the red is returned
  ![fetch_node](assets/tree_node.svg)

  Returns `:error` if no node is found.
  """
  @spec fetch_node(t(), MPTree.match_fn()) :: {:ok, Node.t()} | :error
  def fetch_node(tree, match_fn) do
    with node when not is_nil(node) <- tree |> MPTree.nodes() |> Enum.find(match_fn) do
      {:ok, node}
    else
      _ -> :error
    end
  end

  @doc """
  Return the first node matching `match_fn`.

  Throws if no node is found.
  """
  @spec fetch_node!(t(), MPTree.match_fn()) :: Node.t()
  def fetch_node!(tree, match_fn) do
    fetch_node(tree, match_fn) |> extract_value!
  end

  @doc """
  Find parent of the node matching `child_fn`.

  In this example, the blue (parent) node is returned.
  ![parent node](assets/tree_parent.svg)

  Returns `:error` if child is not found or if child is the root node.
  """
  @spec fetch_parent(t(), match_fn()) :: {:ok, Node.t()} | :error
  def fetch_parent(%__MODULE__{nodes: nodes} = _tree, child_fn) when is_function(child_fn, 1) do
    with {:ok, nodes} <- Seeker.filter(nodes, child_fn, keep: [:ancestors, :matched]) do
      cond do
        length(nodes) >= 2 -> {:ok, Enum.at(nodes, -2)}
        true -> :error
      end
    end
  end

  @doc """
  Find parent of the node matching `child_fn`.

  Throws if child is not found or if child is the root node.
  """
  @spec fetch_parent!(t(), match_fn()) :: Node.t()
  def fetch_parent!(%__MODULE__{} = tree, child_fn) when is_function(child_fn, 1) do
    fetch_parent(tree, child_fn) |> extract_value!
  end

  @doc """
  Get the path from a starting node to an ending node.

  In this example, the green (starting matched), red (ending matched), and blue (path) nodes are returned
  in `:exit` or `:enter` tuples
  ![transition path](assets/tree_transition.svg)

  The above returns
  ```elixir
  [
    exit: f,
    enter: a,
    enter: b
  ]
  ```
  Returns `:error` if no node is found.
  """
  @spec fetch_transition_path(t(), MPTree.match_fn(), MPTree.match_fn()) ::
          {:ok, transition_path()} | :error
  def fetch_transition_path(tree, start_match_fn, end_match_fn) do
    with {:ok, up_path} <- fetch_ancestors_and_self(tree, start_match_fn),
         {:ok, down_path} <- fetch_ancestors_and_self(tree, end_match_fn) do
      path = do_transition_path(up_path, down_path)
      {:ok, path}
    end
  end

  @doc """
  Get the path from a starting node to an ending node.

  Throws if no node is found.
  """
  @spec fetch_transition_path!(t(), MPTree.match_fn(), MPTree.match_fn()) :: transition_path()
  def fetch_transition_path!(tree, start_match_fn, end_match_fn) do
    fetch_transition_path(tree, start_match_fn, end_match_fn) |> extract_value!
  end

  @doc """
  Get all nodes.
  """
  @spec nodes(t()) :: [Node.t(), ...]
  def nodes(%__MODULE__{nodes: val} = _tree), do: val

  @spec __max_node_id__(t()) :: NodeMeta.id()
  def __max_node_id__(%__MODULE__{nodes: [root | _]}) do
    Node.__count_self_and_descendents__(root)
  end

  @spec __node_count__(t()) :: pos_integer
  def __node_count__(%__MODULE__{nodes: [root | _]}) do
    Node.__count_self_and_descendents__(root)
  end

  @spec __node_ids__(t()) :: [NodeMeta.id()]
  def __node_ids__(%__MODULE__{} = tree) do
    Enum.to_list(NodeMeta.__starting_node_id__()..__max_node_id__(tree))
  end

  @spec __root__(t()) :: Node.t()
  def __root__(tree)
  def __root__(%__MODULE__{nodes: [root | _]}), do: root

  #####################################
  # HELPERS

  @spec do_transition_path(nodes(), nodes()) :: transition_path()
  defp do_transition_path([head1, head2 | state_tail], [head1, head2 | destination_tail]) do
    do_transition_path([head2 | state_tail], [head2 | destination_tail])
  end

  defp do_transition_path([head1 | state_tail], [head1 | destination_tail]) do
    state_path_items = Stream.map(state_tail, &{:exit, &1})
    destination_path_items = Enum.map(destination_tail, &{:enter, &1})
    Enum.reduce(state_path_items, destination_path_items, &[&1 | &2])
  end

  defp _children_from_tail(tail, parent, children \\ [])

  defp _children_from_tail([], _, children) do
    children
  end

  defp _children_from_tail([child | rest], parent, children) do
    if Node.__parent_and_last_child__?(parent, child) do
      [child | children]
    else
      child_descendent_count = Node.__count_descendents__(child)
      tail = Enum.drop(rest, child_descendent_count)
      _children_from_tail(tail, parent, [child | children])
    end
  end
end
