defmodule Statechart.FutureFeature.SubchartTest do
  use ExUnit.Case
  import Statechart.Chart.Query
  import Statechart.Tree

  describe "subchart/2" do
    test "successfully inserts a sub-chart into a parent chart" do
      defmodule SubChart do
        use Statechart

        statechart do
          state :on
          state :off
        end
      end

      defmodule MainChart do
        use Statechart

        statechart do
          state :flarb
          subchart :flazzl, SubChart
        end
      end

      chart = MainChart.__statechart__()
      assert length(fetch_nodes!(chart)) == 5
      assert {:ok, 3} = fetch_id_by_state(chart, :flazzl)
    end
  end
end
