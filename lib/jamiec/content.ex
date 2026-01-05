defmodule Jamiec.Content do
  @moduledoc """
  The Content context.
  """

  import Ecto.Query, warn: false
  alias Jamiec.Repo
  alias Jamiec.Accounts.Scope
  alias Jamiec.Content.Post
  alias Jamiec.Content.Tag

  @doc """
  Returns a list of posts based on the scope.

  If the scope contains a logged-in user, returns all posts.
  If the scope is nil (not logged in), returns only published posts.

  Posts are ordered by inserted_at descending.
  """
  def list_posts(%Scope{user: user}) when not is_nil(user) do
    Post
    |> order_by(desc: :inserted_at, desc: :id)
    |> Repo.all()
  end

  def list_posts(_scope) do
    Post
    |> where(status: :published)
    |> order_by(desc: :inserted_at, desc: :id)
    |> Repo.all()
  end

  @doc """
  Gets a single post.

  Raises `Ecto.NoResultsError` if the Post does not exist.
  """
  def get_post!(id), do: Repo.get!(Post, id)

  @doc """
  Creates a post.
  """
  def create_post(attrs \\ %{}) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a post.
  """
  def update_post(%Post{} = post, attrs) do
    post
    |> Post.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a post.
  """
  def delete_post(%Post{} = post) do
    Repo.delete(post)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking post changes.
  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  @doc """
  Returns all tags.
  """
  def list_tags do
    Repo.all(Tag)
  end

  @doc """
  Gets a single tag.

  Raises `Ecto.NoResultsError` if the Tag does not exist.
  """
  def get_tag!(id), do: Repo.get!(Tag, id)

  @doc """
  Creates a tag.
  """
  def create_tag(attrs \\ %{}) do
    %Tag{}
    |> Tag.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Deletes a tag.
  """
  def delete_tag(%Tag{} = tag) do
    Repo.delete(tag)
  end
end
