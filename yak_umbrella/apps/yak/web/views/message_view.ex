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

  @doc """
  Renders a command result as json
  """
  def render("command.json", %{succeeded: suceeded, result: result}) do
    %{
      suceeded: suceeded,
      result: result
    }
  end
end