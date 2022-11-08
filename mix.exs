defmodule MPTree.MixProject do
  use Mix.Project

  @project_name :modified_preorder_tree
  @repo_url "https://github.com/jonathanchukinas/modified_preorder_tree"

  def project do
    [
      app: @project_name,
      version: "0.2.0",
      aliases: aliases(),
      preferred_cli_env: [
        check: :test,
        c: :test
      ],
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),

      # Docs
      name: "MPTree",
      source_url: @repo_url,
      docs: docs(),

      # Package
      package: package(),
      description: """
      Modified Preorder Tree Traversal Data Structure
      """
    ]
  end

  defp package do
    [
      name: @project_name,
      licenses: ["MIT"],
      links: %{
        # LATER add
        # "Changelog" => "tbd"
        "GitHub" => @repo_url
      }
    ]
  end

  defp aliases do
    [
      check: ~w/test dialyzer/,
      c: "check"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(env) when env in ~w/dev test/a, do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Project Dependencies
      {:typed_struct, "~> 0.2.1"},

      # Development and test dependencies
      {:dialyxir, "~>1.1", only: [:dev, :test], runtime: false},
      {:stream_data, "~>0.5", only: [:dev, :test]},

      # Documentation dependencies
      {:ex_doc, "~> 0.29", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      assets: "assets",
      authors: ["Jonathan Chukinas"],
      extras: ["CHANGELOG.md"],
      formatters: ["html"],
      main: "MPTree"
    ]
  end

  defp dialyzer do
    [
      plt_core_path: "tmp/plts",
      plt_file: {:no_warn, "tmp/plts/dialyzer.plt"}
    ]
  end
end
