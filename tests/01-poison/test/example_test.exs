defmodule ExampleTest do
  use ExUnit.Case, async: true

  test "Poison works" do
    assert Poison.encode!(%{}) == "{}"
  end
end
