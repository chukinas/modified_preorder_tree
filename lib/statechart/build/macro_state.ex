defmodule Statechart.Build.MacroState do
  @moduledoc false
  # This module does the heavy lifting for the `Statechart.state` macro.

  import Statechart.Chart.Query
  import Statechart.Tree
  alias Statechart.Chart
  alias Statechart.Node
  alias __MODULE__
  alias Statechart.Build
  alias Statechart.Build.Acc
  alias Statechart.Build.Chart, as: BuildChart
  alias Statechart.Build.Node, as: BuildNode
  alias Statechart.Metadata
  alias Statechart.MetadataAccess

  def build_ast(name, opts, do_block) do
    quote do
      require Build

      Build.raise_if_out_of_scope(
        "state/1 and state/2 must be called inside a statechart/2 block"
      )

      MacroState.__on_enter__(@__sc_build_step__, __ENV__, unquote(name), unquote(opts))
      unquote(do_block)
      MacroState.__on_exit__(__ENV__)
    end
  end

  def insert_node(env, name) do
    old_chart = Acc.chart(env)
    parent_id = Acc.current_id(env)

    with :ok <- validate_name!(old_chart, name),
         new_node = Node.new(name, metadata: Metadata.from_env(env)),
         {:ok, new_chart} <- insert(old_chart, new_node, parent_id),
         {:ok, new_node_id} <- fetch_id_by_state(new_chart, name) do
      env
      |> Acc.put_chart(new_chart)
      |> Acc.push_current_id(new_node_id)

      :ok
    else
      {:error, reason} ->
        raise reason
    end
  end

  @spec __on_enter__(Build.build_step(), Macro.Env.t(), Node.name(), Keyword.t()) :: :ok
  def __on_enter__(build_step, env, name, opts \\ [])

  def __on_enter__(:insert_nodes = _build_step, env, name, _opts) do
    insert_node(env, name)
  end

  def __on_enter__(:insert_transitions_and_defaults, env, _name, opts) do
    chart = Acc.chart(env)

    origin_node = BuildChart.fetch_node_by_metadata!(chart, Metadata.from_env(env))
    Acc.push_current_id(env, Node.id(origin_node))

    case Keyword.fetch(opts, :default) do
      {:ok, target_name} ->
        insert_default(chart, origin_node, target_name, env)

      # no default specified
      :error ->
        :ok
    end
  end

  def __on_enter__(_build_step, env, _name, _ops) do
    Build.__push_current_id__(env)
  end

  @spec insert_default(Chart.t(), Node.t(), Node.name(), Macro.Env.t()) :: :ok
  defp insert_default(chart, origin_node, target_name, env) do
    :ok = BuildNode.validate_branch_node!(origin_node)
    target_id = BuildChart.fetch_id_by_state!(chart, target_name)
    :ok = BuildChart.validate_target_id_is_descendent!(chart, Node.id(origin_node), target_id)
    new_origin_node = BuildNode.put_new_default!(origin_node, target_id)
    new_chart = Statechart.Build.Tree.replace_node!(chart, new_origin_node)

    env
    |> Acc.push_current_id(Node.id(origin_node))
    |> Acc.put_chart(new_chart)

    :ok
  end

  @spec __on_exit__(Macro.Env.t()) :: :ok
  def __on_exit__(env) do
    _current_id = Acc.pop_id!(env)
    :ok
  end

  @spec validate_name!(Chart.t(), Node.name()) :: :ok | no_return
  defp validate_name!(chart, name) do
    unless is_atom(name) do
      msg = "expected state arg1 to be an atom, got: #{inspect(name)}"
      raise StatechartError, msg
    end

    case local_nodes_by_name(chart, name) do
      [] ->
        :ok

      [node_with_same_name | _tail] ->
        {:ok, line_number} = MetadataAccess.fetch_line_number(node_with_same_name)
        msg = "a state with name '#{name}' was already declared on line #{line_number}"
        raise StatechartError, msg
    end
  end
end
