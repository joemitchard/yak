defmodule Yak.ChatChannel do
  use Yak.Web, :channel

  alias Yak.MessageView

  @doc """
  Handles join requests from the client
  Returns messages associated to the chat.
  """
  def join("chats:" <> chat_id, params, socket) do
    last_seen_id = params["last_seen_id"] || 0
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

    # Adds a bunch of jsonified messages in the response payload
    resp = %{messages: Phoenix.View.render_many(messages, MessageView, "message.json")}

    {:ok, resp, assign(socket, :chat_id, chat_id)}
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

  defp broadcast_message(socket, message) do
    # ensure user is loaded
    message = Repo.preload(message, :user)

    rendered_msg = Phoenix.View.render(MessageView, "message.json", %{message: message})

    broadcast! socket, "new_message", rendered_msg
  end
end