defmodule Exbalance.Mixfile do
  use Mix.Project

  def project do
    [
      app: :exbalance,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :plug]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 0.5", only: :dev, runtime: false},
      {:cowboy, "~> 1.1"},
      {:plug, "~> 1.4"},
      {:httpoison, "~> 0.13.0"}
    ]
  end
end
