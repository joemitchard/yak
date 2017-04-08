defmodule Yak.ChannelMonitor do
  use GenServer

  # todo, refactor this out to an agent

  # API
  @doc """
  Start the gen server, naming it as __MODULE__
  """
  def start_link(init_state) do
    GenServer.start_link(__MODULE__, init_state, name: __MODULE__)  
  end

  @doc """
  Provides the current state of the requested channel
  """
  def current(channel) do
    GenServer.call(__MODULE__, {:current, channel})
  end

  @doc """
  Adds new user to the channel 
  """
  def join(channel, user) do
    GenServer.call(__MODULE__, {:join, channel, user})
  end

  @doc """
  Removes the user from the channel
  """
  def leave(channel, user_id) do
    GenServer.call(__MODULE__, {:leave, channel, user_id})
  end

  # Callbacks
  def init(state) do
    {:ok, state}
  end

  def handle_call({:current, channel}, _from, state) do
    {:reply, Map.get(state, channel), state}
  end

  def handle_call({:join, channel, user}, _from, state) do
    new_state = case Map.get(state, channel) do
      # Nothing found for the channel, create a new entry
      nil ->
        Map.put(state, channel, [user])
      
      # Update an existing user list
      users ->
        Map.put(state, channel, Enum.uniq([user | users]))
    end

    {:reply, Map.get(new_state, channel), new_state}
  end

  def handle_call({:leave, channel, user_id}, _from, state) do
    # Drop the user from the channel list
    new_users =
      state
      |> Map.get(channel)
      |> Enum.reject(&(&1.id == user_id))

    new_state = Map.update!(state, channel, fn _ -> new_users end)

    {:reply, Map.get(new_state, channel), new_state}
  end

end