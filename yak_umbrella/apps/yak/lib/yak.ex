defmodule Yak.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    children = [
      supervisor(Yak.Repo, []),
      supervisor(Yak.Web.Endpoint, []),

      supervisor(Yak.Chat.Supervisor, []),

      # worker(Yak.UserMonitor, [])
    ]

    opts = [strategy: :one_for_one, name: Yak.Supervisor]
    Supervisor.start_link(children, opts)
  end

end
