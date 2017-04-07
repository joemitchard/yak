defmodule Yak.Repo.Migrations.AddMessage do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :body, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :chat_id, references(:chats, on_delete: :nothing)

      timestamps()
    end

    create index(:messages, [:user_id])
    create index(:messages, [:chat_id])
   end
end
