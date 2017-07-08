defmodule Yak.Web.SessionController do
  @moduledoc """
  Module to maintain and control user login session
  """
  use Yak.Web, :controller

  alias Yak.Web.Auth

  @doc """
  Renders the login page
  """
  def new(conn, _) do
    render conn, "new.html"
  end

  @doc """
  Handles login
  """
  def create(conn, %{"session" => %{"username" => user, "password" => pass}}) do
    case Auth.login(conn, user, pass, repo: Repo) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome")
        |> redirect(to: chat_path(conn, :list))

      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username or password")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> Auth.logout()
    |> redirect(to: page_path(conn, :index))
  end


end
