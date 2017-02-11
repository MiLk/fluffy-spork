defmodule FluffySpork.Mixfile do
  use Mix.Project

  def project do
    [app: :fluffy_spork,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :tentacat, :cowboy, :plug],
     mod: {FluffySpork, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:tentacat, git: "https://github.com/edgurgel/tentacat.git"},
      {:cowboy, "~> 1.1.2"},
      {:plug, "~> 1.3"},
      {:poison, "~> 3.0"},
    ]
  end
end
