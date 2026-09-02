defmodule RexplorerIndexer.MixProject do
  use Mix.Project

  def project do
    [
      app: :rexplorer_indexer,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {RexplorerIndexer.Application, []}
    ]
  end

  defp deps do
    [
      {:rexplorer, in_umbrella: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
