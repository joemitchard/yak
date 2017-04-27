defmodule Graze.ParserTest do
  use ExUnit.Case, async: true

  alias Graze.Parser

  test "a valid input parses correctly" do
    command = Parser.parse("/mirror hello")
    assert {:mirror, _fun, "hello"} = command
  end

  test "an input with no parameters parses correctly" do
    command = Parser.parse("/list")
    assert {:list, _fun} = command
  end

  test "a command with valid format but no command returns :nocmd" do
    command = Parser.parse("/test hello")
    assert :nocmd = command
  end

  test "an invalid input returns :nocmd" do
    command = Parser.parse("test hello")
    assert :nocmd = command
  end

end