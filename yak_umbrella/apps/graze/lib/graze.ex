defmodule Graze do
  @moduledoc """
  A command parser and handler for Yak.
  Possible idea to have the server hand out work to a pool of handlers...
  """
  use Application

  def start(_type, _args) do

    opts = [
      size: 10,
      max_overflow: 5
    ]

    Graze.Supervisor.start_link(opts)
  end
end
