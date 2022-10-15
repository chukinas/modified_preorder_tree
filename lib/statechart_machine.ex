defmodule Statechart.Machine do
  @moduledoc """
  Create and manipulate state machines defined by `Statechart.statechart/2`

  Build a `t:t/1` off a statechart 'template'

  The above three "steps" are all about declaring a statechart in a safe, robust way.
  In `Statechart`, when we say 'statechart', you can think of it as a template
  (similar to a class in OOO).
  To do anything meaningful with the statechart, you need to first instantiate a
  machine (similar to an object in OOO) that is built from that template.
  We will transform this data structure as we pass events to it.

  ```
  defmodule ToggleStatechart do
    use Statechart
    statechart do
      # ...
    end
  end

  toggle_machine = machine(ToggleStatechart)
  ```
  """

  defstruct [:statechart_module, :state, :context]

  @typedoc """
  This is the state type
  """
  @type state :: any()

  # TODO it'd be really cool if TypedStruct could do this
  @typep t(statechart_module, context) :: %__MODULE__{
           statechart_module: statechart_module,
           context: context,
           state: state()
         }

  @typedoc """
  This is the machine type
  """
  @opaque t(statechart_module) :: t(statechart_module, nil)

  @typedoc """
  This is the event type
  """
  @type event :: any

  # Just for messing around with private and opaque types
  @doc false
  @spec __new__(statechart_module) :: t(statechart_module, nil) when statechart_module: module()
  def __new__(statechart_module) do
    %__MODULE__{
      statechart_module: statechart_module,
      context: nil,
      # TODO get the default
      state: nil
    }
  end

  # TODO this doc refs a machine function.
  @doc crc: :reducers
  @doc """
  Send an `t:event/0` to an `t:t/1`


  The `statechart/3` macro injects a `t:t/1` function into the module,
  which is then called as follows:
  ```
  defmodule ToggleStatechart do
    use Statechart
    statechart do
      state :stay_here_forever, default: true
    end
  end

  machine = ToggleStatechart.machine()
  ```

  With the machine now available
  """
  @spec transition(t(statechart_module), event()) :: t(statechart_module)
        when statechart_module: module
  def transition(machine, _event), do: machine

  @doc crc: :converters
  @doc """
  Get the machine's current state.
  """
  @spec state(t(any)) :: state()
  def state(%__MODULE__{state: val}), do: val

  @doc crc: :converters
  @doc """
  Get the `t:module/0` that defines the machine's statechart.
  """
  @spec statechart_module(t(statechart_module)) :: statechart_module
        when statechart_module: module()
  def statechart_module(%__MODULE__{statechart_module: val}), do: val
end
