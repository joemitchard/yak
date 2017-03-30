defmodule Yak.UserView do
  use Yak.Web, :view
  
  alias Yak.User

  def first_name(%User{name: name}) do
    name
    |> String.split(" ")
    |> Enum.at(0)
  end
end