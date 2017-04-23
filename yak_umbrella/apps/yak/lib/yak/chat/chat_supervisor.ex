defmodule Yak.Chat.Supervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Yak.Chat.Monitor, []),
      worker(Yak.Chat.Waiting, [])
    ]

    opts = [
      strategy: :one_for_one
    ]
    
    supervise(children, opts)
  end
end