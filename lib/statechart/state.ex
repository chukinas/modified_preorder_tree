defmodule Statechart.State do
  @moduledoc false

  alias Statechart.Node

  @typedoc """
  Describes the current state.

  Being a valid type isn't necessarilly good enough by itself, of course.
  State is always subject to validation by the `Statechart.Transitions` module.
  """
  @type t :: Node.name() | Node.id()

  # TODO this is here just to appease dialyzer for now
  @type name :: any()
end
