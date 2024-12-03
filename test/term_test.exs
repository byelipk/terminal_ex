defmodule TermTest do
  use ExUnit.Case
  doctest Term

  test "greets the world" do
    assert Term.hello() == :world
  end
end
