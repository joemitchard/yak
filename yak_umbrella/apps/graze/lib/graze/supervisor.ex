defmodule Graze.Supervisor do
  @moduledoc """
  Supervisor for the Graze application.
  """
  use Supervisor

  def start_link(:ok) do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      supervisor(Graze.WorkerSupervisor, []),
      worker(Graze.Server, [])
    ]

    supervise(children, [strategy: :one_for_one])
  end
end