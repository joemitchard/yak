defmodule Yak.Web.Router do
  use Yak.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Yak.Web.Auth, repo: Yak.Repo
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Yak.Web do
    pipe_through :browser # Use the default browser stack

    # route
    get "/", PageController, :index

    resources "/users", UserController, only: [:index, :show, :new, :create]
    resources "/sessions", SessionController, only: [:new, :create, :delete]

  end
  
  scope "/yak", Yak.Web do
    pipe_through [:browser, :authenticate_user]

    get "/chats/list", ChatController, :list
    resources "/chats", ChatController, only: [:index, :show, :new, :create]
  end

  # Other scopes may use custom stacks.
  # scope "/api", Yak do
  #   pipe_through :api
  # end
end
