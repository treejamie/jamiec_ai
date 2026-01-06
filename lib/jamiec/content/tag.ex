defmodule Jamiec.Content.Tag do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Jamiec.Content.Post

  schema "tags" do
    field :tag, :string
    field :slug, :string

    many_to_many :posts, Post, join_through: "posts_tags"
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:tag, :slug])
    |> validate_required([:tag])
    |> generate_slug()
    |> validate_required([:slug])
    |> unique_constraint(:slug)
  end

  defp generate_slug(changeset) do
    case get_change(changeset, :tag) do
      nil ->
        changeset

      tag ->
        slug =
          tag
          |> String.downcase()
          |> String.replace(~r/[^a-z0-9\s-]/, "")
          |> String.replace(~r/\s+/, "-")
          |> String.trim("-")

        put_change(changeset, :slug, slug)
    end
  end
end
