defmodule ChromeRemoteInterfaceTest do
  use ExUnit.Case
  doctest ChromeRemoteInterface

  test "greets the world" do
    assert ChromeRemoteInterface.hello() == :world
  end
end
