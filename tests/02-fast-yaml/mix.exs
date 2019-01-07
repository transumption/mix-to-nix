defmodule Example.MixProject do
  use Mix.Project

  def project do
    [
      app: :example,
      version: "0.0.0",
      deps: [
        fast_yaml: "1.0.17",
        pc: "1.10.0",
        rebar3_hex: "6.2.0"
      ]
    ]
  end
end
