defmodule ElixirToJSON.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_to_json,
      escript: [main_module: ElixirToJSON],
      version: "0.0.0",
      deps: [
        {:jason, git: "https://github.com/michalmuskala/jason", tag: "v1.1.2"}
      ]
    ]
  end
end
