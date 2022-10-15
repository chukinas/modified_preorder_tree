defmodule Statechart.Build do
  @moduledoc false
  # Some helpers for the various Statechart macros

  use TypedStruct
  alias Statechart.Node
  require Statechart.Node
  alias Statechart.Build.Acc
  alias Statechart.Build.Chart, as: BuildChart
  alias Statechart.Metadata

  # CONSIDER do transitions, default, and subcharts.. can they all go at the same time?
  @build_steps ~w/
    insert_nodes
    insert_subcharts
    insert_actions
    insert_transitions_and_defaults
    /a

  @type build_step :: :insert_nodes | :insert_transitions_and_defaults | :insert_subcharts

  def build_steps, do: @build_steps

  #####################################
  # HELPERS

  @doc false
  @spec __push_current_id__(Macro.Env.t()) :: :ok
  def __push_current_id__(env) do
    node = BuildChart.fetch_node_by_metadata!(Acc.chart(env), Metadata.from_env(env))
    Acc.push_current_id(env, Node.id(node))
    :ok
  end

  # TODO this should be used somewhere besides state/2? If so, create tests for it
  defmacro raise_if_out_of_scope(message) do
    quote do
      unless Module.has_attribute?(__MODULE__, :__sc_build_step__) do
        raise StatechartError, unquote(message)
      end
    end
  end
end
