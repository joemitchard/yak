defmodule Yak.Web.PageController do
  use Yak.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
