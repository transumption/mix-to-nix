alias MixToNix.Template

defmodule MixToNix.Derivation do
  use Template

  deftemplate(:template, "default.nix.eex", [:closure])

  deftemplate(:fetch_git, "fetch_git.nix.eex", [:name, :url, :rev])
  deftemplate(:fetch_hex, "fetch_hex.nix.eex", [:name, :hex_name, :version, :sha256])

  def render_dependency({name, {:hex, hex_name, version, sha256, _tools, _children, "hexpm"}}) do
    fetch_hex(name, hex_name, version, sha256)
  end

  def render_dependency({name, {:git, url, rev, _}}) do
    fetch_git(name, url, rev)
  end

  def render(dependencies) do
    dependencies
    |> Map.to_list()
    |> Enum.map(&render_dependency/1)
    |> Enum.join()
    |> template()
  end
end
