defmodule Statechart.NoContext do
  @moduledoc false
  defstruct []
  def new, do: %__MODULE__{}
  @type t :: %__MODULE__{}
end
