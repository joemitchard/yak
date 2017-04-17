defmodule Graze.Server do
  @moduledoc """
  Graze server, handles parsing and handling of commands.
  """

  # TODO -> Turn this into a pool of N amounts of workers, if one is available, use that
  #         Otherwise rerutn :noproc and decide how to handle that on client.

  # Workers still not exiting gracefully, need to spawn a pool of them (default 10?), use those as avaialble workers and queue the rest or return :no-roc if client not willing to block

  use GenServer

  alias Graze.Worker

  defmodule State do
    defstruct monitors: nil,
              workers: nil
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
    n = 10
    # take n from args
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    workers = spawn_pool(n)
    {:ok, %State{monitors: monitors, workers: workers}}
  end

  @doc """
  Uses an avaialble worker in the pool
  """
  def handle_call({:read, message}, {from_pid, _ref}, %State{monitors: monitors, workers: workers} = state) do
    
    case workers do
      [worker | rest] ->
        ref = Process.monitor(worker)
        true = :ets.insert(monitors, {worker, {from_pid, ref}})
        Worker.process(worker, message)
        {:reply, :ok, %{state | workers: rest}}
      [] ->
        IO.puts("??????")
        {:reply, :noproc, state}
    end

  end

  @doc """
  Handles workers that have successfully completed parsing commands.

  When completes this puts the worker back in the pool
  """
  def handle_info({:result, worker_pid, result}, %{monitors: monitors, workers: workers} = state) do
    case :ets.lookup(monitors, worker_pid) do
      [{worker_pid, {pid, ref}}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, worker_pid)
        respond(pid, result)
        {:noreply, %{state | workers: [worker_pid | workers]}}

      [] ->
        {:noreply, state}
    end
  end

  @doc """
  Handles workers that crash
  This should respawn worker
  """
  def handle_info({:EXIT, pid, _reason}, state = %{monitors: monitors, workers: workers}) do
    case :ets.lookup(monitors, pid) do
      [{pid, {_from_pid, ref}}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, pid)
        {:noreply, %{state | workers: [spawn_worker() | workers]}}

      [] ->
        # Process not monitored...?
        IO.puts("worker crashed, no monitor")
        {:noreply, state}
    end
  end


  ### HELPER FUNCTIONS ###
  defp spawn_pool(0), do: []
  defp spawn_pool(n) do
    [spawn_worker() | spawn_pool(n-1)]
  end

  # This will break, need to update worker to not start on init
  def spawn_worker() do
    {:ok, pid} = Supervisor.start_child(Graze.WorkerSupervisor, [])
    Process.link(pid)
    pid
  end

  defp respond(pid, result) do
    send(pid, {:processed, result})
  end

end