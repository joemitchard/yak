defmodule Graze.Server do
  @moduledoc """
  Graze server, handles parsing and handling of commands.

  Turn this into a parsing pool... 
  On receving a message, store the From pid in state with a spawned worker task to carry out the process.
  handle info to receive a reply back from the worker task, remove item from state, and respond to From with the result
  Probably spawn the workers through a worker supervisor to handle crashing processes, or trap proc exits and handle that way
  """
  use GenServer

  alias Graze.Parser

  ### API ###
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def read(message) when is_binary(message) do
    GenServer.call(__MODULE__, {:read, message})
  end

  ### SERVER ###
  def init() do
    {:ok, %{}}
  end

  def handle_call({:read, message}, _from, state) do
    case Parser.parse(message) do
      {_command, message} ->
        {:reply, message, state}
      
      :nocmd ->
        {:reply, :error, state}
    end
  end


  ### HELPER FUNCTIONS ###
  

end