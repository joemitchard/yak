defmodule Yak.UserTests do
  use Yak.ModelCase, async: true

  alias Yak.User

  @valid_attrs %{name: "A User", username: "Dave", password: "secret", email: "email@somewhere.com"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "changeset does not accept long username" do
    attrs = Map.put(@valid_attrs, :username, String.duplicate("a", 30))
    changeset = User.registration_changeset(%User{}, attrs)

    assert changeset.errors[:username] == {"should be at most %{count} character(s)", [count: 20, validation: :length, max: 20]}
  end

  test "registration_changeset username must be at least 4 chars long" do
    attrs = Map.put(@valid_attrs, :username, "Ben")
    changeset = User.registration_changeset(%User{}, attrs)

    assert changeset.errors[:username] == {"should be at least %{count} character(s)", [count: 4, validation: :length, min: 4]}
  end

  test "registration_changeset password must be at least 6 chars long" do
    attrs = Map.put(@valid_attrs, :password, "12345")
    changeset = User.registration_changeset(%User{}, attrs)

    assert changeset.errors[:password] == {"should be at least %{count} character(s)", [count: 6, validation: :length, min: 6]}
  end

  test "registration_changeset with valid attrs hashes password" do
    attrs = Map.put(@valid_attrs, :password, "123456")
    changeset = User.registration_changeset(%User{}, attrs)

    %{password: pass, password_hash: pass_hash} = changeset.changes

    assert changeset.valid?
    assert pass_hash
    assert Comeonin.Bcrypt.checkpw(pass, pass_hash)
  end
end