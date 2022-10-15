defmodule StatechartTest do
  use ExUnit.Case
  import Statechart.Chart.Query
  import Statechart.Tree
  alias Statechart.Node

  use Statechart

  # BuildTest chart:
  statechart do
  end

  describe "statechart/2" do
    test "create a statechart within a submodule" do
      use Statechart

      statechart module: ChartDefinedViaOpts do
        nil
      end
    end

    test "raises if statechart was already called in this module" do
      # TODO rename this error
      assert_raise StatechartError, ~r/Only one statechart/, fn ->
        defmodule InvalidDoubleStatechart do
          use Statechart
          statechart do: nil
          statechart do: nil
        end
      end
    end
  end

  describe "state/1 or /2" do
    test "raises if called before statechart block" do
      assert_raise StatechartError, ~r/must be called inside/, fn ->
        defmodule StateOutOfScopeBefore do
          import Statechart
          state :naughty
        end
      end
    end

    test "raises if called after a statechart block" do
      assert_raise StatechartError, ~r/must be called inside/, fn ->
        defmodule StateOutOfScopeAfter do
          use Statechart

          statechart do
          end

          import Statechart
          state :naughty
        end
      end
    end

    test "raises if default opt if given to a leaf node" do
      assert_raise StatechartError, ~r/cannot assign a default to a leaf/, fn ->
        defmodule DefaultPassedToLeafNode do
          use Statechart

          statechart do
            state :a, default: :b do
            end

            state :b
          end
        end
      end
    end

    test "raises if default target is not a descendent" do
      assert_raise StatechartError, ~r/must be a descendent/, fn ->
        defmodule DefaultIsNotDescendent do
          use Statechart

          statechart do
            state :a, default: :b do
              state :c
            end

            state :b
          end
        end
      end
    end

    test "do-block is optional" do
      defmodule StateWithNoDoBlock do
        use Statechart

        statechart do
          state :hello
        end
      end
    end

    test "correctly nests states" do
      defmodule Sample do
        use Statechart

        statechart do
          state :a do
            state :b do
              :GOTO_D >>> :d

              state :c do
                state :d do
                end
              end
            end
          end
        end
      end

      chart = Sample.__statechart__()
      {:ok, 5 = d_node_id} = fetch_id_by_state(chart, :d)
      {:ok, d_path} = fetch_path_nodes_by_id(chart, d_node_id)
      assert length(d_path) == 5
      d_path_as_atoms = Enum.map(d_path, &Node.name/1)
      assert d_path_as_atoms == ~w/root a b c d/a
    end

    test "raises a StatechartError on non-atom state names" do
      assert_raise StatechartError, ~r/expected state arg1 to be an atom/, fn ->
        defmodule InvalidStateName do
          use Statechart
          statechart do: state(%{})
        end
      end
    end

    test "raises on duplicate **local** state name" do
      assert_raise StatechartError, ~r/was already declared on line/, fn ->
        defmodule DuplicateLocalNodeName do
          use Statechart

          statechart do
            state :on
            state :on
          end
        end
      end
    end
  end

  # This should test for the line number
  # Should give suggestions for matching names ("Did you mean ...?")
  describe ">>>/2" do
    test "an event targetting a branch node must provides a default path to a leaf node"

    test "raises if event targets a root that doesn't resolve"
    # This should test for the line number
    test "raises a StatechartError on invalid event names"
    test "raises if target does not resolve to a leaf node"
    test "raises if target does not exist"

    test "raises if one of node's ancestors already has a transition with this event" do
      assert_raise StatechartError, ~r/events must be unique/, fn ->
        defmodule MyStatechart do
          use Statechart

          statechart do
            :AMBIGUOUS_EVENT >>> :b

            state :a do
              :AMBIGUOUS_EVENT >>> :c
            end

            state :b
            state :c
          end
        end
      end
    end
  end

  describe "on/1" do
    test "raises on invalid input" do
      assert_raise StatechartError, ~r/single-item keyword list with a/, fn ->
        defmodule MyStatechart do
          use Statechart

          statechart do
            state :the_only_state do
              on not_a_valid_action_type: fn -> IO.puts("This will never print") end
            end
          end
        end
      end
    end
  end
end
