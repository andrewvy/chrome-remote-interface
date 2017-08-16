defmodule ChromeRemoteInterface.Mixfile do
  use Mix.Project

  def project do
    [
      app: :chrome_remote_interface,
      version: "0.1.0",
      elixir: "~> 1.5",
      start_permanent: Mix.env == :prod,
      deps: deps()
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
      {:poison, "~> 3.1"},
      {:httpipe_adapters_hackney, "~> 0.9"},
      {:httpipe, "~> 0.9"},
      {:websockex, "~> 0.4.0"}
    ]
  end
end
