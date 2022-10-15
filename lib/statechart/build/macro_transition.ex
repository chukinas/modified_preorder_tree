defmodule Statechart.Build.MacroTransition do
  @moduledoc false
  # This module does the heavy lifting for the `Statechart.transition` macro.

  import Statechart.Chart.Query
  require Statechart.Node, as: Node
  alias __MODULE__
  alias Statechart.Build
  alias Statechart.Build.Acc
  alias Statechart.Build.Tree, as: BuildTree
  alias Statechart.Event
  alias Statechart.Metadata
  alias Statechart.MetadataAccess
  alias Statechart.Transition

  def build_ast(event, target_name) do
    quote bind_quoted: [event: event, target_name: target_name] do
      MacroTransition.build(@__sc_build_step__, __ENV__, event, target_name)
    end
  end

  @spec build(Build.build_step(), Macro.Env.t(), Event.t(), Node.name()) :: :ok
  def build(:insert_transitions_and_defaults, env, event, target_name) do
    chart = Acc.chart(env)
    node_id = Acc.current_id(env)

    unless :ok == Event.validate(event) do
      raise StatechartError, "expect event to be an atom or module, got: #{inspect(event)}"
    end

    if transition = find_transition_in_family_tree(chart, node_id, event) do
      msg =
        "events must be unique within a node and among its path and descendents, the event " <>
          inspect(event) <>
          " is already registered on line " <>
          inspect(MetadataAccess.fetch_line_number(transition))

      raise StatechartError, msg
    end

    # TODO this should raise a StatechartError
    target_id =
      case fetch_id_by_state(chart, target_name) do
        {:ok, target_id} ->
          target_id

        _ ->
          msg =
            "Expected to find a target state with name :#{target_name} but none was found, " <>
              "valid names are: #{inspect(local_node_names(chart))}"

          raise StatechartError, msg
      end

    transition = Transition.new(event, target_id, Metadata.from_env(env))

    chart = BuildTree.update_node_by_id!(chart, node_id, &Node.put_transition(&1, transition))
    Acc.put_chart(env, chart)
    :ok
  end

  def build(_build_step, _env, _event, _destination_node_name) do
    :ok
  end
end
