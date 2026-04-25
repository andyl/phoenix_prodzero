defmodule PhoenixLite.MixProject do
  use Mix.Project

  def project do
    [
      app: :phoenix_lite,
      version: "0.0.1",
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
      {:igniter, "~> 0.6", only: [:dev, :test]},
        {:commit_hook, path: "~/src/Tool/commit_hook"}
    ]
  end
end
