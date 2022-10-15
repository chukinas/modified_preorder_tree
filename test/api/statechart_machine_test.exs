defmodule Statechart.MachineTest do
  use ExUnit.Case
  require Statechart.Machine, as: Machine

  defmodule TestStatechart do
    use Statechart

    statechart default: :on do
      state :on do
        :TOGGLE >>> :off
      end

      state :off do
        :TOGGLE >>> :on
      end
    end
  end

  #####################################
  # CONSTRUCTORS
  #####################################

  describe "TestStatechart.machine/0" do
    # alias Statechart.MachineTest.TestStatechart
    test "returns a `Statechart.Machine.t`" do
      assert %Machine{} = TestStatechart.machine()
    end
  end

  #####################################
  # REDUCERS
  #####################################

  describe "Statechart.Machine.transition/1" do
    test "throws when passed anything but a Machine struct"
    test "returns an `t:module()` otherwise"
    test "the returned module contains __statechart_build__/0 function"
  end

  #####################################
  # CONVERTERS
  #####################################

  describe "Statechart.Machine.state/1" do
    test "throws when passed anything but a Machine struct"
    test "returns an `t:atom()` otherwise"
  end

  describe "Statechart.Machine.statechart_module/1" do
    test "throws when passed anything but a Machine struct"
    test "returns an `t:module()` otherwise"
    test "the returned module contains __statechart_build__/0 function"
  end
end
