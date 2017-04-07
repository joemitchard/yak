defmodule Yak.MessageView do
  use Yak.Web, :view

  @doc """
  Renders a message as json
  """
  def render("message.json", %{message: msg}) do
    %{
      id: msg.id,
      body: msg.body,
      user: render_one(msg.user, Yak.UserView, "user.json")
    }
  end
end