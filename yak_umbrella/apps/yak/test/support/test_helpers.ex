defmodule Yak.TestHelpers do
  alias Yak.Repo
  alias Yak.User
  
  @doc """
  Insert a user with the defaults or those passed in.
  """
  def insert_user(attrs \\ %{}) do
    changes = Dict.merge(%{
      name: "Long Name",
      username: "user#{Base.encode16(:crypto.rand_bytes(8))}",
      password: "supersecret",
      email: "email@somewhere.com"
    }, attrs)

    %User{}
    |> User.registration_changeset(changes)
    |> Repo.insert!()
  end

  @doc """
  insert a chat into the repo
  """
  def insert_chat(user, attrs \\ %{}) do
    user
    |> Ecto.build_assoc(:chats, attrs)
    |> Repo.insert!()
  end
end