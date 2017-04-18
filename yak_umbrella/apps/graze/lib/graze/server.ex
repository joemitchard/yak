defmodule Graze.Server do
  @moduledoc """
  Graze server, handles parsing and handling of commands.
  """

  # needs more queues
  # needs to handle crashed workers

  use GenServer

  alias Graze.Worker
  alias Graze.WorkerSupervisor

  defmodule State do
    defstruct monitors: nil,
              workers: nil,
              overflow: nil,
              max_overflow: nil
  end

  ### API ###
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def read(message) when is_binary(message) do
    GenServer.call(__MODULE__, {:read, message})
  end

  ### SERVER ###
  
  def init(opts \\ []) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    state = %State{monitors: monitors, overflow: 0}
    init(opts, state)
  end

  def init([{:size, size} | rest], state) do
    workers = spawn_pool(size)
    init(rest, %{state | workers: workers})
  end

  def init([{:max_overflow, max_overflow} | rest], state) do
    init(rest, %{state | max_overflow: max_overflow})
  end

  def init([_, rest], state), do: init(rest, state)
  def init([], state) do
    {:ok, state}
  end

  @doc """
  Uses an avaialble worker in the pool
  """
  def handle_call({:read, message}, {from_pid, _ref}, state) do
    
    %{
      monitors: monitors, 
      workers: workers,
      overflow: overflow,
      max_overflow: max_overflow
    } = state

    case workers do
      [worker | rest] ->
        worker_ref = Process.monitor(worker)
        true = :ets.insert(monitors, {worker, from_pid, worker_ref})
        Worker.process(worker, message)
        {:reply, :ok, %{state | workers: rest}}

      [] when max_overflow > 0 and overflow <= max_overflow ->
        {worker, ref} = spawn_overflow_worker()
        true = :ets.insert(monitors, {worker, from_pid, ref})
        Worker.process(worker, message)
        {:reply, :ok, %{state | overflow: overflow + 1}}

      [] ->
        # TODO handle a queue of users?
        {:reply, :noproc, state}
    end

  end

  @doc """
  Handles workers that have successfully completed parsing commands.

  When completes this puts the worker back in the pool
  """
  def handle_info({:result, worker_pid, result}, state) do

    %{
      monitors: monitors, 
      workers: workers,
      overflow: overflow
    } = state

    case :ets.lookup(monitors, worker_pid) do
      [{worker_pid, from_pid, ref}] when overflow > 0 ->
        handle_completed(worker_pid, from_pid, ref, monitors, result)
        dismiss_worker(worker_pid)
        {:noreply, %{state | overflow: overflow - 1}}

      [{worker_pid, from_pid, ref}] ->
        handle_completed(worker_pid, from_pid, ref, monitors, result)
        {:noreply, %{state | workers: [worker_pid | workers]}}

      [] ->
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
    {:ok, pid} = Supervisor.start_child(WorkerSupervisor, [])
    Process.link(pid)
    pid
  end

  def spawn_overflow_worker() do
    worker = spawn_worker()
    ref = Process.monitor(worker)
    {worker, ref}
  end

  defp dismiss_worker(pid) do
    true = Process.unlink(pid)
    Supervisor.terminate_child(WorkerSupervisor, pid)
  end

  defp handle_completed(worker_pid, from_pid, ref, monitors, result) do
    true = Process.demonitor(ref)
    true = :ets.delete(monitors, worker_pid)
    respond(from_pid, result)
  end

  defp respond(pid, result) do
    send(pid, {:processed, result})
  end

end