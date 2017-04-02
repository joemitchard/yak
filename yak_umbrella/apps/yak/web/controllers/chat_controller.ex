defmodule Yak.ChatController do
  @moduledoc """
  Module for chat management and indexing
  
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

  def index(conn, _params, user) do
    chats = Repo.all(user_chats(user))
    render(conn, "index.html", chats: chats)
  end

  def new(conn, _params, user) do
    changeset = 
      user
      |> build_assoc(:chats)
      |> Chat.changeset()
    render(conn, "new.html", changeset: changeset)
  end

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

  def show(conn, %{"id" => id}, user) do
    chat = Repo.get!(user_chats(user), id)
    render(conn, "show.html", chat: chat)
  end

  # returns an ecto query with the users videos
  defp user_chats(user) do
    assoc(user, :chats)
  end
end