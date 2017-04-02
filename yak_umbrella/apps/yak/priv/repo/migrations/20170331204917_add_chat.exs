defmodule Yak.Repo.Migrations.AddChat do
  use Ecto.Migration

  def change do
    create table(:chats) do
      add :name, :string
      add :description, :text
      add :user_id, references(:users, on_delete: :nothing)
      add :is_private, :boolean, default: false

      timestamps()
    end

    create index(:chats, [:user_id])
  end
end
