defmodule Yak.ChatChannel do
  use Yak.Web, :channel

  alias Yak.MessageView
  alias Yak.UserView
  alias Yak.Chat.Monitor

  @doc """
  Handles join requests from the client
  Returns messages associated to the chat.
  """
  def join("chats:" <> chat_id, params, socket) do
    last_seen_id = params["last_seen_id"] || 0

    user = Repo.get(Yak.User, socket.assigns.user_id)

    chat_id = String.to_integer(chat_id)
    chat = Repo.get!(Yak.Chat, chat_id)

    # Query to find all messages associated with the chat
    messages = Repo.all(
      from m in assoc(chat, :messages),
        where: m.id > ^last_seen_id,
        order_by: [asc: m.inserted_at, asc: m.id],
        limit: 200,
        preload: [:user]
    )

    current_users = Monitor.join(chat_id, user)

    send self(), {:new_user, user}

    # Adds a bunch of jsonified messages in the response payload
    resp = %{
      messages: Phoenix.View.render_many(messages, MessageView, "message.json"),
      users: Phoenix.View.render_many(current_users, UserView, "user.json")
    }

    {:ok, resp, assign(socket, :chat_id, chat_id)}
  end

  @doc """
  Handles users leaving the chat
  """
  def terminate(_reason, socket) do
    user_id = socket.assigns.user_id
    chat_id = socket.assigns.chat_id

    users = Monitor.leave(chat_id, user_id)
  
    broadcast_users_update(socket, users)

    :ok
  end

  @doc """
  Intercept all handle_in calls and adds a user parameter
  """
  def handle_in(event, params, socket) do
    user = Repo.get(Yak.User, socket.assigns.user_id)
    handle_in(event, params, user, socket)
  end

  @doc """
  Handles inbound new messages and broadcasts them to other users

  Inserts the message to repo, on success it broadcasts
  """
  def handle_in("new_message", params, user, socket) do
    changeset = 
      user
      |> build_assoc(:messages, chat_id: socket.assigns.chat_id)
      |> Yak.Message.changeset(params)

    case Repo.insert(changeset) do
      # Normal case, broadcast message to other clients
      {:ok, message} ->
        broadcast_message(socket, message)
        {:reply, :ok, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: changeset}}, socket}
    end
  end

  def handle_in("new_command", params, _user, socket) do

    # Here I should ask the server to process the message,
    # On reply, I should handle the message

    case Map.fetch(params, "body") do
      {:ok, command} ->
        # push_command(socket, {true, command})
        process_command(socket, command)

      nil ->
        push_command(socket, {false, ""})
    end
    {:reply, :ok, socket}
  end

  @doc """
  Handle a new user entering into the channel
  """
  def handle_info({:new_user, user}, socket) do
    broadcast_new_user(socket, user)
    {:noreply, socket}
  end

  # inform clients of a new user joining
  defp broadcast_new_user(socket, user) do
    broadcast! socket, "new_user", Phoenix.View.render(UserView, "user.json", %{user: user})
  end

  # provide an updated users list to clients
  defp broadcast_users_update(socket, users) do
    msg = %{
      users: Phoenix.View.render_many(users, UserView, "user.json")
    }

    broadcast! socket, "user_left", msg
  end

  # Send the clients a message
  defp broadcast_message(socket, message) do
    # ensure user is loaded
    message = Repo.preload(message, :user)

    rendered_msg = Phoenix.View.render(MessageView, "message.json", %{message: message})

    broadcast! socket, "new_message", rendered_msg
  end

  defp push_command(socket, {succeeded, result}) do
    renderd_cmd = Phoenix.View.render(MessageView, "command.json", %{succeeded: succeeded, result: result})

    push socket, "new_command", renderd_cmd
  end

  defp process_command(socket, command) do
    # here I need to store the socket in an agent with a unique ref
    # Pass the command to the process mapper
    # On receive of the message, get the process info and handle it using push_command

  end
end