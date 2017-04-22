defmodule Graze.Server do
  @moduledoc """
  Graze server, handles parsing and handling of commands.
  """
  # needs to handle crashed workers
  # also needs to handle crashed clients

  use GenServer

  alias Graze.Worker
  alias Graze.WorkerSupervisor

  defmodule State do
    defstruct monitors: nil,      # ets table for pairing workers and users
              workers: nil,       # list of workers in pool
              overflow: nil,      # amount over pool size
              max_overflow: nil,  # amount allowed to overflow
              waiting: nil        # queue waiting clients
  end

  ### API ###
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def read(ref, message) when is_binary(message) do
    GenServer.call(__MODULE__, {:read, ref, message})
  end

  ### SERVER ###
  
  def init(opts \\ []) do
    Process.flag(:trap_exit, true)
    monitors = :ets.new(:monitors, [:private])
    waiting = :queue.new()
    state = %State{monitors: monitors, waiting: waiting, overflow: 0}
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
  Uses an avaialble worker in the pool to process a message
  """
  def handle_call({:read, client_ref, message}, {from_pid, _ref} = from, state) do
    
    %{
      monitors: monitors, 
      workers: workers,
      overflow: overflow,
      max_overflow: max_overflow,
      waiting: waiting
    } = state

    case workers do
      [worker | rest] ->
        handle_read({from_pid, from}, worker, {client_ref, message}, monitors)
        {:reply, :ok, %{state | workers: rest}}

      [] when max_overflow > 0 and overflow <= max_overflow ->
        worker = spawn_overflow_worker()
        handle_read({from_pid, from}, worker, {client_ref, message}, monitors)
        {:reply, :ok, %{state | overflow: overflow + 1}}

      [] ->
        :queue.in({from, {client_ref, message}}, waiting)
        {:reply, :noproc, state}
    end

  end

  @doc """
  Handles workers that have successfully completed parsing commands.

  When completes this puts the worker back in the pool
  """
  def handle_info({:result, worker_pid, result}, state) do

    %{
      monitors: monitors 
    } = state

    case :ets.lookup(monitors, worker_pid) do
      [{worker_pid, from, ref, client_ref}] ->
        true = Process.demonitor(ref)
        true = :ets.delete(monitors, worker_pid)
        new_state = handle_completed({from, result, client_ref}, worker_pid, state)
        {:noreply, new_state}

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
    worker
  end

  defp dismiss_worker(pid) do
    true = Process.unlink(pid)
    Supervisor.terminate_child(WorkerSupervisor, pid)
  end


  defp handle_read({from_pid, from}, worker, {client_ref, message}, monitors) do
    ref = Process.monitor(from_pid)
    true = :ets.insert(monitors, {worker, from, ref, client_ref})
    Worker.process(worker, message)
  end

  # Handles completed workers, if there is a user in the queue it 
  # puts the worker back to work on next in queue
  defp handle_completed({from, result, client_ref}, worker_pid, state) do
    %{ 
      waiting: waiting,
      workers: workers,
      monitors: monitors,
      overflow: overflow
    } = state

    case :queue.out(waiting) do
      {{:value, {from, {client_ref, message}}}, rest} ->
        worker_ref = Process.monitor(worker_pid)
        true = :ets.insert(monitors, {worker_pid, from, worker_ref, client_ref})
        Worker.process(worker_pid, message)
        %{state | waiting: rest}
      
      {:empty, rest} when overflow > 0 ->
        respond(from, result, client_ref)
        dismiss_worker(worker_pid)
        %{state | waiting: rest, overflow: overflow - 1}
      
      {:empty, rest} ->
        respond(from, result, client_ref)
        %{state | waiting: rest, workers: [worker_pid | workers]}

    end
  end

  defp respond(from, result, client_ref) do
    GenServer.reply(from, {:processed, client_ref, result})
  end

end
