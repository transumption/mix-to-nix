defmodule Mix2Nix.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix2nix,
      escript: [main_module: Mix2Nix.CLI],
      version: "0.1.0"
    ]
  end
end
