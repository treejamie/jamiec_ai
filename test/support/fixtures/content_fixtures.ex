defmodule Jamiec.ContentFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Jamiec.Content` context.
  """

  alias Jamiec.Content

  def valid_post_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      title: "Test Post #{System.unique_integer()}",
      description: "A test post description",
      markdown_body: "# Hello\n\nThis is a test post.",
      status: :draft
    })
  end

  def post_fixture(attrs \\ %{}) do
    {:ok, post} =
      attrs
      |> valid_post_attributes()
      |> Content.create_post()

    post
  end
end
