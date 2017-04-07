defmodule Yak.Chat do
  use Yak.Web, :model

  schema "chats" do
    field :name,        :string
    field :description, :string
    field :is_private,  :boolean
    belongs_to :user,   Yak.User
    has_many :messages, Yak.Message

    timestamps()
  end

  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :description, :is_private, :user_id])
    |> validate_required([:name, :description])
  end
end