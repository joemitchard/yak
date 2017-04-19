defmodule Graze.Parser do
  @moduledoc """
  A command parser for Graze.
  """

  # possibly split the handler out from the parser

  @doc """
  Parse and handle the message
  """
  def parse(message) when is_binary(message) do
    case get_command(message) do
      {:mirror, rest} ->
        {:mirror, String.reverse(rest)}

      {:up, rest} ->
        {:up, String.upcase(rest)}

      {:down, rest} ->
        {:down, String.downcase(rest)}

      :nocmd ->
        :nocmd
    end

  end


  defp get_command(command) do
    case String.split(command, " ", parts: 2) do
      ["/mirror", rest] ->
        {:mirror, rest}

      ["/up", rest] ->
        {:up, rest}

      ["/down", rest] ->
        {:down, rest}
        
      _ ->
        :nocmd
    end
  end

end