defmodule Yak.UserRepoTest do
  use Yak.ModelCase
  alias Yak.User

  @valid_attrs %{name: "A User", username: "Username", email: "email@somewhere.com"}

  test "converts unique_constraintmon username to error" do
    insert_user(username: "test.user")

    attrs = Map.put(@valid_attrs, :username, "test.user")
    changeset = User.changeset(%User{}, attrs)

    assert {:error, changeset} = Repo.insert(changeset)
    assert changeset.errors()[:username] == {"has already been taken", []}
  end
end