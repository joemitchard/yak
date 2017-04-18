defmodule Graze.Worker do
  @moduledoc """
  
  """
  use GenServer

  alias Graze.Parser

  ### API ###
  # drop server and use static name
  def start_link() do
    GenServer.start_link(__MODULE__, [])
  end

  def process(pid, message) do
    GenServer.cast(pid, {:process, message})
  end

  ### SERVER ###
  def init() do
    {:ok, %{}}
  end

  def handle_cast({:process, message}, state) do
    case Parser.parse(message) do
      {_command, msg} ->
        complete(msg)
        {:noreply, state}
      
      :nocmd ->
        complete(:nocmd)
        {:noreply, state}
    end
  end

  ### PRIV ###
  defp complete(msg) do
    send(Graze.Server, {:result, self(), msg})
  end

end