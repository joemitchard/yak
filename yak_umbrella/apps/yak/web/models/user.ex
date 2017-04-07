defmodule Yak.User do
  use Yak.Web, :model

  schema "users" do
    field :name,          :string
    field :username,      :string
    field :email,         :string
    field :password,      :string, virtual: true
    field :password_hash, :string

    has_many :chats,      Yak.Chat
    has_many :messages,   Yak.Message

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :username, :email, :password_hash])
    |> validate_required([:name, :username, :email])
    |> validate_length(:username, min: 4, max: 20)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  # This is an extension of changeset, that handles passwords on registration
  def registration_changeset(model, params) do
    model
    |> changeset(params)
    |> cast(params, [:password])
    |> validate_length(:password, min: 6, max: 100)
    |> put_password_hash()
  end

  defp put_password_hash(changeset) do
    case changeset do
      # valid case, handle password
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(pass))
      
      _ ->
        changeset
    end
  end


end