defmodule Graze.Server do
  @moduledoc """
  Graze server, handles parsing and handling of commands.

  Turn this into a parsing pool... 
  On receving a message, store the From pid in state with a spawned worker task to carry out the process.
  handle info to receive a reply back from the worker task, remove item from state, and respond to From with the result
  Probably spawn the workers through a worker supervisor to handle crashing processes, or trap proc exits and handle that way
  """
  use GenServer

  defmodule State do
    defstruct monitors: nil 
  end

  ### API ###
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def read(message) when is_binary(message) do
    GenServer.call(__MODULE__, {:read, message})
  end

  ### SERVER ###
  def init(:ok) do
    monitors = :ets.new(:monitors, [:private])
    {:ok, %State{monitors: monitors}}
  end

  def handle_call({:read, message}, {from_pid, _ref}, %State{monitors: monitors} = state) do
    
    worker_pid = spawn_worker(message)

    ref = Process.monitor(from_pid)

    true = :ets.insert(monitors, {worker_pid, ref})

    # possible kill spawned workers, maybe store them and use them if there are any

    {:reply, :ok, state}
  end

  def handle_info({:result, worker_pid, result}, state) do
    IO.puts(result)
    {:noreply, state}
  end

  ### HELPER FUNCTIONS ###
  def spawn_worker(message) do
    {:ok, pid} = Supervisor.start_child(Graze.WorkerSupervisor, [message])
    pid
  end

end