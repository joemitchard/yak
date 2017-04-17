defmodule Graze.Worker do
  @moduledoc """
  
  """
  use GenServer

  alias Graze.Parser

  ### API ###
  # drop server and use static name
  def start_link(message) do
    GenServer.start_link(__MODULE__, message)
  end

  ### SERVER ###
  def init(message) do
    send(self(), {:process, message})
    {:ok, %{}}
  end

  def handle_info({:process, message}, state) do
    IO.puts("#{inspect self()} processing")
    case Parser.parse(message) do
      {_command, message} ->
        send_response(message)
        {:stop, :normal, state}
      
      :nocmd ->
        send_response(:nocmd)
        {:stop, :normal, state}
    end
  end

  ### PRIV ###
  defp send_response(msg) do
    send(Graze.Server, {:result, self(), msg})
  end

end