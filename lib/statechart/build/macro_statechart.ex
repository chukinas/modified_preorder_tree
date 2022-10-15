defmodule Statechart.Build.MacroStatechart do
  @moduledoc false
  # This module does the heavy lifting for the `Statechart.statechart` macro.

  alias __MODULE__
  alias Statechart.Build
  alias Statechart.Build.Acc
  alias Statechart.Build.MacroState
  alias Statechart.Chart

  @spec build_ast(any, keyword) :: Macro.t()
  def build_ast(block, opts) do
    quote do
      MacroStatechart.__on_enter__(__ENV__)

      require MacroStatechart
      import Build
      import Statechart

      for build_step <- Build.build_steps() do
        @__sc_build_step__ build_step
        MacroStatechart.__root_update__(build_step, __ENV__, unquote(opts))
        unquote(block)
      end

      MacroStatechart.__on_exit__(__ENV__)
      @before_compile unquote(__MODULE__)
    end
  end

  def __root_update__(:insert_transitions_and_defaults = build_step, env, opts) do
    MacroState.__on_enter__(build_step, env, :root, opts)
  end

  def __root_update__(_build_step, _env, _opts) do
    :ok
  end

  defmacro __before_compile__(env) do
    chart = Acc.chart(env)
    Acc.delete_attribute(env)

    quote do
      @spec __statechart__() :: Chart.t()
      def __statechart__, do: unquote(Macro.escape(chart))

      alias Statechart.Machine
      @spec machine :: Machine.t(__MODULE__)
      def machine, do: Machine.__new__(__MODULE__)
    end
  end

  @spec __on_enter__(Macro.Env.t()) :: :ok
  def __on_enter__(%Macro.Env{} = env) do
    if Module.has_attribute?(env.module, :__sc_statechart__) do
      raise StatechartError, "Only one statechart call may be made per module"
    end

    chart = Chart.from_env(env)
    # TODO test for bad default input in statechart
    Module.register_attribute(env.module, :__sc_build_step__, [])
    Module.put_attribute(env.module, :__sc_statechart__, nil)
    Acc.put_new(env, chart)
    :ok
  end

  @spec __on_exit__(Macro.Env.t()) :: :ok
  def __on_exit__(env) do
    Module.delete_attribute(env.module, :__sc_build_step__)
    :ok
  end
end
