defmodule ExAlsa.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_alsa,
      version: "0.1.0",
      elixir: "~> 1.13",
      compilers: [:elixir_make] ++ Mix.compilers(),
      make_cwd: "c_src",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_doc, "~> 0.22.1", only: :dev, runtime: false},
      {:benchee, "~> 1.0", only: [:test, :dev]}
    ]
  end
end
