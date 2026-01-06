defmodule Jamiec.Content.Post do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Jamiec.Content.Tag

  @statuses [:draft, :published, :hidden]

  schema "posts" do
    field :title, :string
    field :description, :string
    field :markdown_body, :string
    field :html_body, :string
    field :status, Ecto.Enum, values: @statuses, default: :draft

    many_to_many :tags, Tag, join_through: "posts_tags"

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :description, :markdown_body, :html_body, :status])
    |> validate_required([:title])
    |> validate_inclusion(:status, @statuses)
    |> convert_markdown_to_html()
  end

  defp convert_markdown_to_html(changeset) do
    case get_change(changeset, :markdown_body) do
      nil ->
        changeset

      markdown ->
        html =
          MDEx.to_html!(markdown,
            extension: [
              strikethrough: true,
              tagfilter: true,
              table: true,
              autolink: true,
              tasklist: true,
              header_ids: ""
            ],
            parse: [smart: true],
            render: [unsafe_: true]
          )

        put_change(changeset, :html_body, html)
    end
  end
end
