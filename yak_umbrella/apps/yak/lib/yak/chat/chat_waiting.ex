defmodule Yak.Chat.Waiting do
  @moduledoc """
  An agent to maintain a queue of sockets currently waiting for a response from
  command parsing
  """

  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Stores a tuple of `socket` and `command` with a key of `ref`
  """
  def put(ref, {socket, command}) do
    Agent.update(__MODULE__, &Map.put(&1, ref, {socket, command}))
  end

  @doc """
  Finds, returns and removes an item that matches the key of `ref`
  """
  def get(ref) do
    Agent.get_and_update(__MODULE__, &Map.pop(&1, ref))
  end
end