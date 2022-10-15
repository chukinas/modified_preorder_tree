defmodule MPTree.Node do
  @moduledoc """
  A Tree is made of many nodes. Here is one.

  A valid `MPTree` node is a map with a `:__mptree_meta__` key holding a value of `t:meta/0`.
  Here is the absolute minimal node you can build:

  ```
  my_node = %{__mptree_meta__: init()}
  ```

  Here's a node implemented as a struct:

  ```
  defmodule MyNode do
    defstruct [:name, __mptree_meta__: init()]

    @type t :: %__MODULE__{
      name: String.t(),
      __mptree_meta__: MPTree.Node.meta()
    }

    new(name), do: %__MODULE__{name: name}
  end

  iex> MyNode.new("hello")
  %MyNode{name: "hello", __mptree_meta__: _}
  ```

  If you're a fan of the excellent little `TypedStruct` library,
  you can just use `MPTree.Node` as a plugin.
  The below module compiles to the exact same result as above,
  but is cleaner, more expressive,
  and hides more `MPTree` implementation details.
  ```
  defmodule MyNode do
    use TypedStruct

    typedstruct do
      plugin MPTree.Node
      field :name, String.t()
    end

    new(name), do: %__MODULE__{name: name}
  end

  iex> MyNode.new("hello")
  %MyNode{name: "hello", __mptree_meta__: _}
  ```

  But it would be easier if you just used the
  """

  use TypedStruct.Plugin
  alias MPTree.Node
  alias MPTree.NodeMeta

  @typedoc """
  Instantiated by `MPTree.Node.init/0` and maintained by `MPTree`
  """
  @opaque meta :: NodeMeta.t()

  @type t :: %{required(:__mptree_meta__) => meta(), optional(any()) => any()}

  #####################################
  # PLUGIN

  @impl TypedStruct.Plugin
  defmacro init(_) do
    quote do
      field :__mptree_meta__, MPTree.NodeMeta.t(), default: MPTree.Node.init()
    end
  end

  #####################################
  # REDUCERS

  # Increase `lft` and/or `rgt` if they're greater than or equal to the `threshold`
  def __incr_lft_rgt__(
        %{__mptree_meta__: %NodeMeta{lft: lft, rgt: rgt} = meta} = node,
        increment_by,
        threshold \\ 0
      ) do
    meta =
      cond do
        lft >= threshold -> %NodeMeta{meta | lft: lft + increment_by, rgt: rgt + increment_by}
        rgt >= threshold -> %NodeMeta{meta | rgt: rgt + increment_by}
        true -> nil
      end

    if meta, do: %{node | __mptree_meta__: meta}, else: node
  end

  def __incr_id__(%{__mptree_meta__: %NodeMeta{} = meta} = node, increment_by) do
    meta = Map.update!(meta, :id, &(&1 + increment_by))
    %{node | __mptree_meta__: meta}
  end

  #####################################
  # CONVERTERS

  def __ancestor_and_descendent__?(
        %{__mptree_meta__: %NodeMeta{} = ancestor},
        %{__mptree_meta__: %NodeMeta{} = descendent}
      ) do
    ancestor.lft < descendent.lft && descendent.rgt < ancestor.rgt
  end

  def __siblings__?(
        %{__mptree_meta__: %NodeMeta{} = brother},
        %{__mptree_meta__: %NodeMeta{} = sister}
      ) do
    brother.rgt + 1 == sister.lft || sister.rgt + 1 == brother.lft
  end

  def __parent_and_last_child__?(
        %{__mptree_meta__: %NodeMeta{} = parent},
        %{__mptree_meta__: %NodeMeta{} = child}
      ) do
    child.rgt + 1 == parent.rgt
  end

  @doc false
  def __leaf__?(%{__mptree_meta__: %NodeMeta{lft: lft, rgt: rgt}}) do
    lft + 1 == rgt
  end

  def __id__(%{__mptree_meta__: %NodeMeta{id: val}}), do: val
  def __lft__(%{__mptree_meta__: %NodeMeta{lft: val}}), do: val
  def __rgt__(%{__mptree_meta__: %NodeMeta{rgt: val}}), do: val
  def __rgt_less_than__(%{__mptree_meta__: %NodeMeta{rgt: rgt}}, threshold), do: rgt < threshold

  @spec __lft_rgt__(t()) :: {NodeMeta.lft(), NodeMeta.rgt()}
  def __lft_rgt__(%{__mptree_meta__: %NodeMeta{lft: lft, rgt: rgt}}), do: {lft, rgt}

  @spec __count_self_and_descendents__(t()) :: pos_integer
  def __count_self_and_descendents__(node) do
    {lft, rgt} = Node.__lft_rgt__(node)
    div(1 + rgt - lft, 2)
  end

  @spec __count_descendents__(t()) :: non_neg_integer
  def __count_descendents__(node) do
    {lft, rgt} = Node.__lft_rgt__(node)
    div(rgt - lft - 1, 2)
  end

  #####################################
  # HELPERS

  @doc """
  When creating your nodes, and before inserting into a tree,
  ensure it has a `:__mptree_meta__` key with the value from `init/0` assigned to it.
  """
  def init, do: NodeMeta.new()
end
