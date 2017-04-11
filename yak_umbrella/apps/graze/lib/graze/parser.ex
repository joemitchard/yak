defmodule Graze.Parser do
  @moduledoc """
  A command parser for Graze.
  """

  def parse(message) when is_binary(message) do
    case get_command(message) do
      {:test, rest} ->
        {:test, String.reverse(rest)}

      :nocmd ->
        :nocmd
    end

  end


  defp get_command(command) do
    case String.split(command, " ", parts: 2) do
      ["/test", rest] ->
        {:test, rest}
        
      _ ->
        :nocmd
    end
  end

end