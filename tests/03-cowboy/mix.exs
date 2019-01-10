defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.0.0",
      deps: [
        cowboy: "2.6.1"
      ]
    ]
  end
end
