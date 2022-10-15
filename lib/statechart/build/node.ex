defmodule Statechart.Build.Node do
  require Statechart.Node, as: Node

  #####################################
  # REDUCERS

  def put_new_default!(origin_node, target_id) do
    case Node.default(origin_node) do
      nil ->
        %Node{origin_node | default: target_id}

      integer when is_integer(integer) ->
        raise StatechartError, "This node already has the given default!"
    end
  end

  @spec push_action!(Node.t(), Node.action_type(), Node.action_fn()) :: Node.t()
  def push_action!(node, action_type, fun) do
    unless Node.is_action_type(action_type) do
      raise StatechartError,
            "the on/1 macro expects a single-item keyword list with a " <>
              "key of either :enter or :exit, got: #{inspect(action_type)}"
    end

    :ok
    Map.update!(node, :actions, &[{action_type, fun} | &1])
  end

  #####################################
  # CONVERTERS

  @spec validate_branch_node!(Node.t()) :: :ok
  def validate_branch_node!(origin_node) do
    unless :ok == Node.validate_branch_node(origin_node) do
      raise StatechartError, "cannot assign a default to a leaf node"
    end

    :ok
  end
end
