defmodule Yak.Auth do
  @moduledoc """
  Authentication plug for the Yak application.
  Maintains the session and token for authenticated users.
  """
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller

  alias Yak.Router.Helpers

  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  def call(conn, repo) do
    user_id = get_session(conn, :user_id)

    cond do
      # User already in conn, carry on
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      # no user in assigns, but user exists, put in assigns
      user = user_id && repo.get(Yak.User, user_id) ->
        put_current_user(conn, user)

      # catchall
      true ->
        assign(conn, :current_user, nil)
    end
  end

  def login_with_username_and_pass(conn, username, given_pass, opts) do
    repo = Keyword.fetch!(opts, :repo)
    user = repo.get_by(Yak.User, username: username)

    cond do
      # user exists and password is correct
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, login(conn, user)}
      
      # user exists, but wrong password
      user ->
        {:error, :unauthorized, conn}

      true ->
        dummy_checkpw()
        {:error, :not_found, conn}
    end
  end

  def login(conn, user) do
    conn
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  def logout(conn) do
    configure_session(conn, drop: true)
  end

  def authenticate_user(conn, _opts) do
    if conn.assigns.current_user do
      conn
    else
      conn
      |> put_flash(:error, "You must be logged in to access this.")
      |> redirect(to: Helpers.page_path(conn, :index))
      |> halt()
    end
  end

  defp put_current_user(conn, user) do
    # handle token here when channel implemented

    conn
    |> assign(:current_user, user)
  end
end