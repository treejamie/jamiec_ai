defmodule Jamiec.Content.Post do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @statuses [:draft, :published, :hidden]

  schema "posts" do
    field :title, :string
    field :description, :string
    field :markdown_body, :string
    field :html_body, :string
    field :status, Ecto.Enum, values: @statuses, default: :draft

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :description, :markdown_body, :html_body, :status])
    |> validate_required([:title])
    |> validate_inclusion(:status, @statuses)
  end
end
