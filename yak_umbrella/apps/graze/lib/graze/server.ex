defmodule Graze.Server do
  @moduledoc """
  Graze server, handles parsing and handling of commands.
  """

  # TODO -> Turn this into a pool of N amounts of workers, if one is available, use that
  #         Otherwise rerutn :noproc and decide how to handle that on client.

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
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    {:ok, %State{monitors: monitors}}
  end

  def handle_call({:read, message}, {from_pid, _ref}, %State{monitors: monitors} = state) do
    
    worker_pid = spawn_worker(message)

    ref = Process.monitor(from_pid)

    true = :ets.insert(monitors, {worker_pid, {from_pid, ref}})

    # possible kill spawned workers, maybe store them and use them if there are any

    {:reply, :ok, state}
  end

  @doc """
  Handles workers that have successfully completed parsing commands.
  """
  def handle_info({:result, worker_pid, result}, %{monitors: monitors} = state) do
    case :ets.lookup(monitors, worker_pid) do
      [{worker_pid, {pid, ref}}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, worker_pid)
        respond(pid, result)
        {:noreply, state}

      [] ->
        {:noreply, state}
    end
  end

  @doc """
  Handle workers that have finished work
  """
  def handle_info({:DOWN, ref, _, _, _}, state = %{monitors: monitors}) do
    case :ets.match(monitors, {:"$1", ref}) do
      [[pid]] ->
        IO.puts("worker finished")
        true = :ets.delete(monitors, pid)
        {:noreply, state}
      [[]] ->
        IO.puts("worker finished - bad match")
        {:noreply, state}
    end
  end

  @doc """
  Handles workers that crash
  """
  def handle_info({:EXIT, pid, _reason}, state = %{monitors: monitors}) do
    case :ets.lookup(monitors, pid) do
      [{pid, {_from_pid, ref}}] ->
        IO.puts("worker crashed")
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        # if pool, need to recreate the worker here
        {:noreply, state}

      [] ->
        # Process not monitored...?
        IO.puts("worker crashed, no monitor")
        {:noreply, state}
    end
  end


  ### HELPER FUNCTIONS ###
  def spawn_worker(message) do
    {:ok, pid} = Supervisor.start_child(Graze.WorkerSupervisor, [message])
    Process.link(pid)
    pid
  end

  def respond(pid, result) do
    send(pid, {:processed, result})
  end

end