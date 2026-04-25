defmodule PhoenixLiteTest do
  use ExUnit.Case
  doctest PhoenixLite

  test "greets the world" do
    assert PhoenixLite.hello() == :world
  end
end
