defmodule MPTree.MixProject do
  use Mix.Project

  @project_name :modified_preorder_tree
  @repo_url "https://github.com/jonathanchukinas/modified_preorder_tree"

  def project do
    [
      app: @project_name,
      version: "0.1.0",
      aliases: aliases(),
      preferred_cli_env: [
        check: :test,
        c: :test
      ],
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "MPTree",
      source_url: @repo_url,
      docs: [
        authors: ["Jonathan Chukinas"],
        formatters: ["html"],
        # groups_for_functions: [
        #   Constructors: &(&1[:crc] == :constructor),
        #   Reducers: &(&1[:crc] == :reducer),
        #   Converters: &(&1[:crc] == :converter),
        #   Helpers: &(&1[:crc] == :helper)
        # ],
        main: "MPTree"
      ],

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
      {:dialyxir, "~>1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:stream_data, "~>0.5", only: [:dev, :test]},
      {:typed_struct, "~> 0.2.1"}
    ]
  end
end
