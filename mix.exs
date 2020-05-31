defmodule Prex.MixProject do
  use Mix.Project

  def project do
    [
      app: :prex,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      escript: [main_module: Prex.CLI],
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
      {:earmark, "~> 1.4.3"},
      {:plug_cowboy, "~> 2.0"},
      {:yaml_elixir, "~> 2.4.0"}
    ]
  end

  defp aliases do
    [
      "escript.bi": ["escript.build", "escript.install"]
    ]
    end
end
