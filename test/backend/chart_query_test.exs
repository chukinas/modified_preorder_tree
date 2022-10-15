defmodule Statechart.Chart.QueryTest do
  use ExUnit.Case
  import Statechart.Chart.Query
  alias Statechart.Transition

  describe "fetch_transition/3" do
    defmodule MyStatechart do
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

    test "returns ok transition tuple" do
      chart = MyStatechart.__statechart__()
      {:ok, 4 = node_id} = fetch_id_by_state(chart, :c)

      assert {:ok, %Transition{}} = fetch_transition(chart, node_id, :GOTO_D)
    end
  end
end
