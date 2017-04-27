defmodule Yak.Auth do
  @moduledoc """
  Authentication plug for the Yak application.
  Maintains the session and token for authenticated users.
  """
  import Plug.Conn
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  import Phoenix.Controller

  alias Yak.Router.Helpers

  @doc """
  Initialises the plug, takes the repo option passed.
  Fails if no repo option passed
  """
  def init(opts) do
    Keyword.fetch!(opts, :repo)
  end

  @doc """
  Call implementation for plug.
  Handles sessions
  """
  def call(conn, repo) do
    user_id = get_session(conn, :user_id)

    cond do
      # User already in conn, carry on
      user = conn.assigns[:current_user] ->
        put_current_user(conn, user)

      # no user in assigns, but user exists, put in assigns
      user = user_id && repo.get(Yak.User, user_id) ->
        put_current_user(conn, user)

      # catch all
      true ->
        assign(conn, :current_user, nil)
    end
  end

  @doc """
  Used to handle logging.

  Asserts that a user exists for `username`, and checks that the `given_pass` 
  hash equals the users passsword.

  On success, this will use `Yak.Auth.login/2` to manipulate conn
  """
  def login(conn, username, given_pass, opts) do
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

  @doc """
  Manipulates `conn` with session information for `user`.

  Redirects to chat directory list
  """
  def login(conn, user) do

    # UserMonitor.user_in(user)

    conn
    |> put_current_user(user)
    |> put_session(:user_id, user.id)
    |> configure_session(renew: true)
  end

  @doc """
  Drops the session.
  """
  def logout(conn) do
    # UserMonitor.user_out(conn.assigns.current_user)
    configure_session(conn, drop: true)
  end

  @doc """
  Checks that a user is assigned to `conn`, otherwise prevents processing
  of the request.
  """
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

  # Assigns the `user` and a Phoenix Token to `conn`
  defp put_current_user(conn, user) do
    token = Phoenix.Token.sign(conn, "user socket", user.id)

    conn
    |> assign(:current_user, user)
    |> assign(:user_token, token)
  end
end