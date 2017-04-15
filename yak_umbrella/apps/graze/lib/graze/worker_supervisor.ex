defmodule Graze.WorkerSupervisor do
  @moduledoc """
  Graze worker supervisor.
  """
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    # If anything in this pools tree fails, restart all
    opts = [
      strategy: :simple_one_for_one
    ]

    children = [
      worker(Graze.Worker, [])
    ]

    supervise(children, opts)
  end
end