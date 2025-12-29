defmodule Jamiec.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :text, null: false
      add :description, :text
      add :markdown_body, :text
      add :html_body, :text
      add :status, :string, null: false, default: "draft"

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:status])
    create index(:posts, [:inserted_at])
  end
end
