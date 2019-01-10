defmodule FakeHexRegistry.MixProject do
  use Mix.Project

  def project do
    [
      app: :fake_hex_registry,
      escript: [main_module: FakeHexRegistry],
      version: "0.0.0",
      deps: [
        jason: "1.1.2"
      ]
    ]
  end
end
