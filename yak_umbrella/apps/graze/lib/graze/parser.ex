defmodule Graze.Parser do
  @moduledoc """
  A command parser for Graze.
  """

  defmodule Command do
    defstruct command: nil,
              name: nil,
              fun: nil,
              description: nil
  end

  @doc """
  Parse the message
  """
  def parse(message) when is_binary(message) do
    get_command(message)
  end

  defp get_commands() do
    [
      %Command{command: "mirror", name: :mirror,  fun: &String.reverse/1,   description: "Reverse the input."},
      %Command{command: "up",     name: :up,      fun: &String.upcase/1,    description: "Convert the input to upper case."},
      %Command{command: "down",   name: :down,    fun: &String.downcase/1,  description: "Convert the input to lower case."},
      %Command{command: "list",   name: :lists,   fun: &list/0,             description: "List the available commands."}
    ]
  end

  # Parse `command`, finding a match from the list of Commands
  defp get_command(command) do
    case String.split(command, " ", parts: 2) do
      # The command begins with "/", now need to find a matching command and process it
      ["/"<>action, rest] ->
        cmd = find_command(action)
        get_command(cmd, rest)

      ["/"<>action] ->
        cmd = find_command(action)
        get_command(cmd, [])

      _ ->
        :nocmd
    end
  end

  defp get_command(:nocmd, _rest), do: :nocmd
  defp get_command(cmd, []), do: {cmd.name, cmd.fun}
  defp get_command(cmd, rest), do: {cmd.name, cmd.fun, rest}

  # returns a command struct or :nocmd
  defp find_command(action) do 
    get_commands()
    |> Enum.find(:nocmd, &(&1.command == action))
  end

  defp list() do
    get_commands()
    |> Enum.map(&("/#{&1.command}: #{&1.description}"))
    |> Enum.join("\n")
  end
end
