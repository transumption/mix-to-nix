defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.0.0",
      deps: [
        poison: "4.0.1"
      ]
    ]
  end
end
