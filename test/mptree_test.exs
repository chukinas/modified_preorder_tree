defmodule MPTreeTest do
  use ExUnit.Case
  use ExUnitProperties
  require MPTree.TestSupport.Generator, as: Generator
  alias MPTree.Node
  alias MPTree.TestSupport.MyNode

  property "A tree always has at least one node (the root node)" do
    check all tree <- Generator.tree() do
      assert MPTree.__node_count__(tree) >= 1
    end
  end

  defp random_node_match_fn(tree) do
    case MPTree.nodes(tree) do
      [] -> fn _ -> true end
      nodes -> Enum.random(nodes).match
    end
  end

  defp no_match_fn(), do: fn _ -> false end

  describe "fetch_ancestors_and_self/2" do
    property "returns ok tuple if match_fn finds no matches" do
      check all tree <- Generator.tree() do
        match_fn = random_node_match_fn(tree)
        assert {:ok, nodes} = MPTree.fetch_ancestors_and_self(tree, match_fn)
        assert length(nodes) > 0
        assert nodes == MPTree.fetch_ancestors_and_self!(tree, match_fn)
      end
    end
  end

  property "converter functions return error if match_fn finds no matches" do
    check all tree <- Generator.tree() do
      match_fn = no_match_fn()
      assert :error = MPTree.fetch_ancestors_and_self(tree, match_fn)
      assert :error = MPTree.fetch_children(tree, match_fn)
    end
  end

  describe "fetch_descendents!/1 ..." do
    property "has number of elements equal to Node.__count_descendents__/1" do
      check all tree <- Generator.tree() do
        for node <- MPTree.nodes(tree) do
          expected_descendent_count = Node.__count_descendents__(node)
          actual_descendent_count = tree |> MPTree.fetch_descendents!(node.match) |> length
          assert expected_descendent_count == actual_descendent_count
        end
      end
    end

    property "has number of elements equal to (rgt - lft - 1) / 2" do
      check all tree <- Generator.tree() do
        for node <- MPTree.nodes(tree) do
          {lft, rgt} = Node.__lft_rgt__(node)
          expected_descendent_count = div(rgt - lft - 1, 2)
          actual_descendent_count = tree |> MPTree.fetch_descendents!(node.match) |> length
          assert expected_descendent_count == actual_descendent_count
        end
      end
    end
  end

  property "fetch_family_tree/2" do
    check all tree <- Generator.tree() do
      match_fn =
        Enum.random([
          no_match_fn(),
          random_node_match_fn(tree)
        ])

      expected_result =
        with {:ok, path} <- MPTree.fetch_ancestors_and_self(tree, match_fn),
             {:ok, descendents} <- MPTree.fetch_descendents(tree, match_fn) do
          {:ok, path ++ descendents}
        end

      assert MPTree.fetch_family_tree(tree, match_fn) == expected_result
    end
  end

  describe "fetch_node/2" do
    property "finds same match as fetch_node!/2" do
      check all tree <- Generator.tree() do
        match_fn = random_node_match_fn(tree)
        assert {:ok, node} = MPTree.fetch_node(tree, match_fn)
        assert node == MPTree.fetch_node!(tree, match_fn)
      end
    end
  end

  describe "Max node id equal to" do
    property "MPTree.__node_count__/1" do
      check all tree <- Generator.tree() do
        assert max_node_id(tree) == MPTree.__node_count__(tree)
      end
    end

    property "MPTree.__max_node_id__/1" do
      check all tree <- Generator.tree() do
        assert max_node_id(tree) == MPTree.__max_node_id__(tree)
      end
    end

    property "root's (1 + rgt - lft) / 2" do
      check all tree <- Generator.tree() do
        {lft, rgt} = tree |> MPTree.__root__() |> Node.__lft_rgt__()
        assert max_node_id(tree) == (1 + rgt - lft) / 2
      end
    end
  end

  describe "update_nodes" do
    property "arity-2 updates all nodes" do
      check all tree <- Generator.tree(),
                new_name <- atom(:alphanumeric) do
        new_tree = MPTree.update_nodes(tree, &MyNode.set_name(&1, new_name))
        assert MPTree.__node_count__(new_tree) == MPTree.__node_count__(tree)

        for node <- MPTree.nodes(new_tree) do
          assert MyNode.name(node) == new_name
        end
      end
    end

    property "arity-3 updates matching nodes" do
      check all tree <- Generator.tree(),
                new_name <- integer() do
        rand_node_id = tree |> MPTree.__node_ids__() |> Enum.random()
        rand_node_fn = &(Node.__id__(&1) == rand_node_id)
        [rand_node] = tree |> MPTree.nodes() |> Enum.filter(rand_node_fn)

        new_tree =
          MPTree.update_nodes(
            tree,
            &MyNode.set_name(&1, new_name),
            &Node.__ancestor_and_descendent__?(rand_node, &1)
          )

        nodes_with_new_name =
          new_tree |> MPTree.nodes() |> Enum.filter(&(MyNode.name(&1) == new_name))

        assert length(nodes_with_new_name) < MPTree.__node_count__(new_tree)
        assert nodes_with_new_name == MPTree.fetch_descendents!(new_tree, rand_node_fn)
      end
    end
  end

  property "Node ID is always greater than or equal to 1 " do
    check all tree <- Generator.tree() do
      for node <- MPTree.nodes(tree) do
        assert Node.__id__(node) >= 1
      end
    end
  end

  describe "MPTree.__root__/1 returns ..." do
    property "the node stored at the head of the nodes list" do
      check all %MPTree{nodes: [root | _]} = tree <- Generator.tree() do
        assert MPTree.__root__(tree) == root
      end
    end

    property "a node with id of 1" do
      check all tree <- Generator.tree() do
        assert 1 == tree |> MPTree.__root__() |> Node.__id__()
      end
    end
  end

  property "Nodes are stored internally in ascending lft order" do
    check all(%MPTree{nodes: nodes} <- Generator.tree()) do
      node_lft_values = Enum.map(nodes, &Node.__lft__/1)
      assert node_lft_values == Enum.sort(node_lft_values)
    end
  end

  property "MPTree.nodes/1 returns nodes in ascending lft order" do
    check all(tree <- Generator.tree()) do
      node_lft_values = tree |> MPTree.nodes() |> Enum.map(&Node.__lft__/1)
      assert node_lft_values == Enum.sort(node_lft_values)
    end
  end

  property "Node lft and rgt values are uniq and the sets don't overlap " do
    check all tree <- Generator.tree() do
      sorted_node_lft_values =
        tree |> MPTree.nodes() |> Stream.map(&Node.__lft__/1) |> Enum.sort()

      assert sorted_node_lft_values == Enum.uniq(sorted_node_lft_values)

      sorted_node_rgt_values =
        tree |> MPTree.nodes() |> Stream.map(&Node.__rgt__/1) |> Enum.sort()

      assert sorted_node_rgt_values == Enum.uniq(sorted_node_rgt_values)

      sorted_lft_and_rgt = Enum.sort(sorted_node_lft_values ++ sorted_node_rgt_values)
      assert sorted_lft_and_rgt == Enum.uniq(sorted_lft_and_rgt)
    end
  end

  describe "Node ids ..." do
    property "are unique" do
      check all(tree <- Generator.tree()) do
        sorted_node_ids = tree |> MPTree.nodes() |> Stream.map(&Node.__id__/1) |> Enum.sort()

        assert sorted_node_ids == Enum.uniq(sorted_node_ids)
      end
    end

    property "contain the same integers as 1..node_count" do
      check all(tree <- Generator.tree()) do
        node_count = MPTree.__node_count__(tree)
        expected_node_ids = 1..node_count |> Enum.sort()
        actual_node_ids = tree |> MPTree.nodes() |> Stream.map(&Node.__id__/1) |> Enum.sort()

        assert expected_node_ids == actual_node_ids
      end
    end
  end

  property "We can calculate node count using root's lft/rgt" do
    check all tree <- Generator.tree() do
      {lft, rgt} = tree |> MPTree.__root__() |> Node.__lft_rgt__()
      expected_node_count = (rgt + 1 - lft) / 2
      assert expected_node_count == length(MPTree.nodes(tree))
      assert expected_node_count == MPTree.__node_count__(tree)
    end
  end

  property "A node's descendents-count == chilren-count + desc-counts of those children" do
    check all tree <- Generator.tree() do
      for node <- MPTree.nodes(tree) do
        actual_descendent_count = Node.__count_descendents__(node)

        calculated_descendent_count =
          tree
          |> MPTree.fetch_children!(node.match)
          |> Stream.map(&Node.__count_self_and_descendents__/1)
          |> Enum.sum()

        assert calculated_descendent_count == actual_descendent_count,
               "#{inspect(node)} expected #{calculated_descendent_count} descendents, got #{actual_descendent_count}"
      end
    end
  end

  property "Once inserted, a node's parent never changes" do
    check all tree <- Generator.tree() do
      for {parent_id, child_names} <-
            tree |> MPTree.nodes() |> Enum.group_by(&MyNode.parent_id/1, &MyNode.name/1),
          parent_id != :root do
        expected_child_names = Enum.sort(child_names)

        parent_match_fn = fn node ->
          Node.__id__(node) == parent_id
        end

        actual_child_names =
          tree
          |> MPTree.fetch_children!(parent_match_fn)
          |> Stream.map(&MyNode.name/1)
          |> Enum.sort()

        assert expected_child_names == actual_child_names,
               "expected parent node (id: #{parent_id}) to have children with names #{inspect(expected_child_names)}, got: #{inspect(actual_child_names)}"
      end
    end
  end

  describe "MPTree.Node" do
    property "__lft__/1 always less than __rgt__1" do
      check all tree <- Generator.tree() do
        for node <- MPTree.nodes(tree) do
          assert Node.__lft__(node) < Node.__rgt__(node)
        end
      end
    end

    property "(rgt - lft) % 2 = 1" do
      check all tree <- Generator.tree() do
        for node <- MPTree.nodes(tree) do
          assert Integer.mod(Node.__rgt__(node) - Node.__lft__(node), 2) == 1
        end
      end
    end
  end

  defp max_node_id(%MPTree{nodes: nodes}) do
    nodes |> Stream.map(&Node.__id__/1) |> Enum.max()
  end
end
