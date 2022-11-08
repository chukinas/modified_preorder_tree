defmodule MPTree.TestSupport.MyNode do
  @moduledoc false
  use TypedStruct
  use MPTree.Util.Inspect, name: "MyNode", keys: ~w/name parent_id __mptree_node__/a
  alias MPTree.Node
  alias MPTree.NodeMeta

  typedstruct enforce: true do
    plugin Node
    field :name, atom() | integer()
    field :parent_id, :root | NodeMeta.id()
    field :match, MPTree.match_fn()
    field :match_parent, MPTree.match_fn()
  end

  # CONSTRUCTORS

  def new(name, parent_id) do
    %__MODULE__{
      name: name,
      parent_id: parent_id,
      match: &(&1.name == name),
      match_parent: &(Node.__id__(&1) == parent_id)
    }
  end

  def root(), do: new(:root, :root)

  # REDUCERS

  def set_name(%__MODULE__{} = node, name) when is_atom(name) or is_integer(name) do
    struct!(node, name: name)
  end

  # CONVERTERS

  def name(%{name: val}), do: val
  def parent_id(%{parent_id: val}), do: val
end
