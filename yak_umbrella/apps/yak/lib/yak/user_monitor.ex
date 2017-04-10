defmodule Yak.UserMonitor do
  @moduledoc """
  A monitor to track users that are currently online.
  """

  def start_link() do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def user_in(user) do
    Agent.update(__MODULE__, fn users -> [user | users] end)
  end

  def user_out(user) do
    Agent.update(__MODULE__, &Enum.reject(&1, fn u -> u.id == user.id end))
  end

  def all() do
    Agent.get(__MODULE__, fn state -> state end)
  end

end