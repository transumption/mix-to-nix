defmodule Mix2Nix.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix2nix,
      deps: [
        {:dialyxir, "~> 0.5", only: :dev, runtime: false}
      ],
      escript: [main_module: Mix2Nix.CLI],
      version: "0.1.0"
    ]
  end
end
