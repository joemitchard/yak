defmodule Yak.ChatController do
  @moduledoc """
  Module for chat management
  
  Show uses ChatChannel
  """
  use Yak.Web, :controller

  alias Yak.Chat

  @doc """
  Calls controller plug for all actions defined in this controller, 
  it adds the user parameter to the controller calls
  """
  def action(conn, _) do
    apply(__MODULE__, action_name(conn),
      [conn, conn.params, conn.assigns.current_user])
  end

  @doc """
  A listing of all chats for the user
  """
  def index(conn, _params, user) do
    chats = Repo.all(user_chats(user))
    render(conn, "index.html", chats: chats)
  end

  @doc """
  Manages the page for chat creaton and validation
  """
  def new(conn, _params, user) do
    changeset = 
      user
      |> build_assoc(:chats)
      |> Chat.changeset()
    render(conn, "new.html", changeset: changeset)
  end

  @doc """
  Handles the creation action for a chat
  """
  def create(conn, %{"chat" => chat_params}, user) do
    changeset = 
      user
      |> build_assoc(:chats)
      |> Chat.changeset(chat_params)

    case Repo.insert(changeset) do
      {:ok, _chat} ->
        conn
        |> put_flash(:info, "Chat created successfully.")
        |> redirect(to: chat_path(conn, :index))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  # TODO -> move this out of chat management... would be better places
  # in a non user dependent controller for public access.
  
  @doc """
  Shows a chat, and opens up a ChatChannel
  """
  def show(conn, %{"id" => id}, _user) do
    chat = Repo.get!(Chat, id)
    render(conn, "show.html", chat: chat)
  end

  # returns an ecto query with the users videos
  defp user_chats(user) do
    assoc(user, :chats)
  end
end