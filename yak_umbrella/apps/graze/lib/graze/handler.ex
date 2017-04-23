defmodule Graze.Handler do
  @moduledoc """
  Command handler for the graze application

  Takes the parsed input and returns the output accourding to a passed function
  """

  @doc """
  Handle the `message` by applying the passed `fun`
  """
  def handle({name, fun, message}) do
    {name, fun.(message)}
  end
  def handle({name, fun}) do
    {name, fun.()}
  end
  def handle(:nocmd), do: :nocmd

end