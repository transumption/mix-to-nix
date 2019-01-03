defmodule ElixirToJSON do
  defimpl Jason.Encoder, for: Tuple do
    def encode(struct, opts) do
      Jason.Encode.list(Tuple.to_list(struct), opts)
    end
  end

  def main([]) do
    {term, _} = Code.eval_string(IO.read(:all))
    IO.puts(Jason.encode!(term))
  end
end
