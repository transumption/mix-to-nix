defmodule MixToNix.Template do
  defmacro __using__([]) do
    quote do
      import unquote(__MODULE__)
      require EEx
    end
  end

  defmacro deftemplate(function_name, filename, args) do
    quote do
      EEx.function_from_file(
        :def,
        unquote(function_name),
        Path.join("templates", unquote(filename)),
        unquote(args)
      )
    end
  end
end
