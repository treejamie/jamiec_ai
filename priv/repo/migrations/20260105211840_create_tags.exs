defmodule Jamiec.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :tag, :string, null: false
      add :slug, :string, null: false
    end

    create unique_index(:tags, [:slug])
  end
end
