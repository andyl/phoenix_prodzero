defmodule PhoenixProdmin.MixProject do
  use Mix.Project

  @version "0.0.6"

  def project do
    [
      app: :phoenix_prodmin,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:git_ops, "~> 2.0", only: [:dev], runtime: false, optional: true},
      {:commit_hook, path: "/home/aleak/src/Tool/commit_hook", only: [:dev], runtime: false, optional: true},
      {:igniter, "~> 0.6", optional: true},
    ]
  end
end
