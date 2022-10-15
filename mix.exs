defmodule Statechart.MixProject do
  use Mix.Project

  def project do
    [
      app: :statechart,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Statechart",
      source_url: "https://github.com/jonathanchukinas/statechart",
      docs: [
        authors: ["Jonathan Chukinas"],
        formatters: ["html"],
        groups_for_functions: [
          # "Step 1: Declare Statechart": &(&1[:section] == 1),
          # "Step 2: Declare States": &(&1[:section] == 2),
          # "Step 3: Declare Transitions and Actions": &(&1[:section] == 3),
          Constructors: &(&1[:crc] == :constructors),
          Reducers: &(&1[:crc] == :reducers),
          Converters: &(&1[:crc] == :converters)
        ],
        groups_for_modules: [
          API: [
            Statechart,
            Statechart.Machine,
            StatechartError
          ],
          Types: [
            Statechart.Node,
            Statechart.Chart,
            Statechart.Event,
            Statechart.Metadata,
            Statechart.Transition
          ],
          Dev: [
            Statechart.Build.Acc,
            Statechart.Chart.Query,
            Statechart.MetadataAccess,
            Statechart.Metadata.HasMetadata,
            Statechart.Tree,
            Statechart.Tree.Insertable,
            Statechart.Tree.IsTree,
            Statechart.Util,
            Statechart.Util.GetterStruct,
            Statechart.Util.Inspect
          ]
        ],
        main: "Statechart"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(env) when env in ~w/dev test/a, do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~>1.1", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:stream_data, "~>0.5", only: [:dev, :test]},
      {:typed_struct, "~> 0.2.1"}
    ]
  end
end
