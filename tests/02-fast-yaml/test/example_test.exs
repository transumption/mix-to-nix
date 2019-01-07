defmodule ExampleTest do
  use ExUnit.Case, async: true

  test "fast_yaml works" do
    {:ok, data} = :fast_yaml.decode("a: b")
    assert data == [[{"a", "b"}]]
  end
end
