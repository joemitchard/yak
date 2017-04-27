defmodule Graze.HandlerTest do
  use ExUnit.Case, async: true

  alias Graze.Parser
  alias Graze.Handler

  test "handling :mirror reverses input" do
    {name, fun, msg} = Parser.parse("/mirror hello")
    result = Handler.handle({name, fun, msg})
    assert {^name, "olleh"} = result
  end

  test "handling an unknown command returns :nocmd" do
    command = Parser.parse("/test hello")
    result = Handler.handle(command)
    assert :nocmd = result
  end
end