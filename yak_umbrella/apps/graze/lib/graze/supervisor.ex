defmodule Graze.Supervisor do
  @moduledoc """
  Supervisor for the Graze application.
  """
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  def init(opts) do
    children = [
      supervisor(Graze.WorkerSupervisor, []),
      worker(Graze.Server, [opts])
    ]

    supervise(children, [strategy: :one_for_one])
  end
end