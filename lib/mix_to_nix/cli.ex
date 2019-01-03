alias MixToNix.Derivation

defmodule MixToNix.CLI do
  def main([path]) do
    {term, _} = Code.eval_file(path)
    IO.puts(Derivation.render(term))
  end
end
