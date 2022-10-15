defmodule Statechart.Build.MacroOnEnterExit do
  @moduledoc false
  # This module does the heavy lifting for the `Statechart.on` macro.

  alias __MODULE__
  alias Statechart.Build
  alias Statechart.Build.Acc
  alias Statechart.Build.Node, as: BuildNode
  alias Statechart.Build.Tree, as: BuildTree
  alias Statechart.Node

  def build_ast(action_type, action_fn) do
    quote bind_quoted: [action_type: action_type, action_fn: action_fn] do
      :ok = MacroOnEnterExit.__action__(@__sc_build_step__, __ENV__, action_type, action_fn)
    end
  end

  @spec __action__(Build.build_step(), Macro.Env.t(), Node.action_type(), Node.action_fn()) :: :ok
  def __action__(build_step, env, action_type, action_fn) do
    case build_step do
      :insert_actions -> insert_action(env, action_type, action_fn)
      _ -> :ok
    end
  end

  # TODO remove new modules from docs
  @spec insert_action(Macro.Env.t(), Node.action_type(), Node.action_fn()) :: :ok
  def insert_action(env, action_type, action_fn) do
    chart = Acc.chart(env)
    current_id = Acc.current_id(env)

    update_node_fn = &BuildNode.push_action!(&1, action_type, action_fn)
    new_chart = BuildTree.update_node_by_id!(chart, current_id, update_node_fn)
    Acc.put_chart(env, new_chart)
    :ok
  end
end
