alias Mix2Nix.Template

defmodule Mix2Nix.Derivation do
  use Template

  deftemplate(:template, "default.nix.eex", [:closure])

  deftemplate(:fetch_git, "fetch_git.nix.eex", [:name, :url, :rev])
  deftemplate(:fetch_hex, "fetch_hex.nix.eex", [:name, :version, :sha256])

  def render_dependency({:hex, name, version, sha256, _tools, _children, "hexpm"}) do
    fetch_hex(name, version, sha256)
  end

  def render(dependencies) do
    dependencies |> Enum.map(&render_dependency/1) |> Enum.join() |> template()
  end
end
