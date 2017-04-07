defmodule Yak.Message do
  use Yak.Web, :model

  schema "messages" do
    field :body,      :string
    belongs_to :user, Yak.User
    belongs_to :chat, Yak.Chat

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:body])
    |> validate_required([:body])
  end
end