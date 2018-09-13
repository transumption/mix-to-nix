alias Mix2Nix.Derivation

defmodule Mix2Nix.CLI do
  def main([path]) do
    {term, _} = Code.eval_file(path)
    IO.puts(Derivation.render(term))
  end
end
