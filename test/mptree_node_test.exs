defmodule MPTree.NodeTest do
  use ExUnit.Case
  alias MPTree.Node
  alias MPTree.NodeMeta

  defmodule MyNode do
    use TypedStruct

    typedstruct enforce: true do
      field :__mptree_node__, NodeMeta.t(), default: NodeMeta.new()
    end

    def new, do: %__MODULE__{}
  end

  describe "Node getters return defaults on newly created node" do
    test "__id__/1" do
      assert 1 == MyNode.new() |> Node.__id__()
    end

    test "__lft__/1" do
      assert 0 == MyNode.new() |> Node.__lft__()
    end

    test "__rgt__/1" do
      assert 1 == MyNode.new() |> Node.__rgt__()
    end
  end

  describe "when passed something other than a node, raise" do
    for function <- [
          &Node.__id__/1,
          &Node.__lft__/1,
          &Node.__rgt__/1
        ] do
      test "#{inspect(function)}" do
        assert_raise FunctionClauseError, fn ->
          unquote(function).(:not_a_node)
        end
      end
    end
  end
end
