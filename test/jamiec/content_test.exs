defmodule Jamiec.ContentTest do
  use Jamiec.DataCase, async: true

  alias Jamiec.Content
  alias Jamiec.Content.Post
  alias Jamiec.Accounts.Scope

  import Jamiec.ContentFixtures
  import Jamiec.AccountsFixtures

  describe "list_posts/1" do
    test "with logged in user returns all posts regardless of status" do
      user = user_fixture()
      scope = Scope.for_user(user)

      draft_post = post_fixture(%{status: :draft})
      published_post = post_fixture(%{status: :published})
      hidden_post = post_fixture(%{status: :hidden})

      posts = Content.list_posts(scope)

      assert length(posts) == 3
      assert draft_post in posts
      assert published_post in posts
      assert hidden_post in posts
    end

    test "with nil scope returns only published posts" do
      _draft_post = post_fixture(%{status: :draft})
      published_post = post_fixture(%{status: :published})
      _hidden_post = post_fixture(%{status: :hidden})

      posts = Content.list_posts(nil)

      assert length(posts) == 1
      assert published_post in posts
    end

    test "posts are ordered by inserted_at descending" do
      user = user_fixture()
      scope = Scope.for_user(user)

      first_post = post_fixture(%{title: "First"})
      Process.sleep(10)
      second_post = post_fixture(%{title: "Second"})
      Process.sleep(10)
      third_post = post_fixture(%{title: "Third"})

      posts = Content.list_posts(scope)

      assert [third_post, second_post, first_post] == posts
    end
  end

  describe "get_post!/1" do
    test "returns the post with given id" do
      post = post_fixture()
      assert Content.get_post!(post.id) == post
    end

    test "raises if post does not exist" do
      assert_raise Ecto.NoResultsError, fn ->
        Content.get_post!(0)
      end
    end
  end

  describe "create_post/1" do
    test "with valid data creates a post" do
      valid_attrs = %{
        title: "My Post",
        description: "A description",
        markdown_body: "# Content",
        status: :published
      }

      assert {:ok, %Post{} = post} = Content.create_post(valid_attrs)
      assert post.title == "My Post"
      assert post.description == "A description"
      assert post.markdown_body == "# Content"
      assert post.status == :published
    end

    test "with missing title returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_post(%{description: "No title"})
    end

    test "defaults status to draft" do
      assert {:ok, %Post{} = post} = Content.create_post(%{title: "Draft Post"})
      assert post.status == :draft
    end
  end

  describe "update_post/2" do
    test "with valid data updates the post" do
      post = post_fixture()
      update_attrs = %{title: "Updated Title", status: :published}

      assert {:ok, %Post{} = updated_post} = Content.update_post(post, update_attrs)
      assert updated_post.title == "Updated Title"
      assert updated_post.status == :published
    end

    test "with invalid data returns error changeset" do
      post = post_fixture()
      assert {:error, %Ecto.Changeset{}} = Content.update_post(post, %{title: nil})
      assert post == Content.get_post!(post.id)
    end
  end

  describe "delete_post/1" do
    test "deletes the post" do
      post = post_fixture()
      assert {:ok, %Post{}} = Content.delete_post(post)
      assert_raise Ecto.NoResultsError, fn -> Content.get_post!(post.id) end
    end
  end

  describe "change_post/2" do
    test "returns a post changeset" do
      post = post_fixture()
      assert %Ecto.Changeset{} = Content.change_post(post)
    end
  end
end
