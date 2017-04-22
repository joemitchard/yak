defmodule Yak do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Yak.Repo, []),
      supervisor(Yak.Endpoint, []),

      worker(Yak.Chat.Monitor, []),
      worker(Yak.UserMonitor, [])
    ]

    opts = [strategy: :one_for_one, name: Yak.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Yak.Endpoint.config_change(changed, removed)
    :ok
  end
end
