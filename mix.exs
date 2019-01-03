defmodule MixToNix.MixProject do
  use Mix.Project

  def project do
    [
      app: :mix_to_nix,
      escript: [main_module: MixToNix.CLI],
      version: "0.1.0"
    ]
  end
end
