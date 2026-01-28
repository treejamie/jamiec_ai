defmodule Jamiec.ContentTest do
  use Jamiec.DataCase, async: true

  alias Jamiec.Content
  alias Jamiec.Content.Post
  alias Jamiec.Content.Tag
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

  describe "markdown to html conversion" do
    test "converts markdown_body to html_body on create" do
      attrs = %{
        title: "Markdown Post",
        markdown_body: "# Hello World\n\nThis is a paragraph."
      }

      assert {:ok, %Post{} = post} = Content.create_post(attrs)
      assert post.html_body =~ "<h1>"
      assert post.html_body =~ "Hello World"
      assert post.html_body =~ "<p>"
      assert post.html_body =~ "This is a paragraph."
    end

    test "converts markdown_body to html_body on update" do
      post = post_fixture(%{markdown_body: "# Original"})

      assert {:ok, %Post{} = updated_post} =
               Content.update_post(post, %{markdown_body: "## Updated Heading"})

      assert updated_post.html_body =~ "<h2>"
      assert updated_post.html_body =~ "Updated Heading"
    end

    test "handles code blocks with syntax highlighting" do
      attrs = %{
        title: "Code Post",
        markdown_body: """
        ```elixir
        def hello do
          :world
        end
        ```
        """
      }

      assert {:ok, %Post{} = post} = Content.create_post(attrs)
      assert post.html_body =~ "<pre"
      assert post.html_body =~ "def"
      assert post.html_body =~ "hello"
    end

    test "does not change html_body when markdown_body is not updated" do
      post = post_fixture(%{markdown_body: "# Original", html_body: nil})
      original_html = post.html_body

      assert {:ok, %Post{} = updated_post} =
               Content.update_post(post, %{title: "New Title"})

      assert updated_post.html_body == original_html
    end

    test "handles GitHub flavored markdown features" do
      attrs = %{
        title: "GFM Post",
        markdown_body: """
        - [x] Task 1
        - [ ] Task 2

        | Column 1 | Column 2 |
        |----------|----------|
        | A        | B        |

        ~~strikethrough~~
        """
      }

      assert {:ok, %Post{} = post} = Content.create_post(attrs)
      assert post.html_body =~ "<table>"
      assert post.html_body =~ "<del>"
      assert post.html_body =~ "strikethrough"
    end
  end

  describe "create_tag/1" do
    test "with valid data creates a tag" do
      assert {:ok, %Tag{} = tag} = Content.create_tag(%{tag: "Elixir"})
      assert tag.tag == "Elixir"
    end

    test "auto-generates slug from tag" do
      assert {:ok, %Tag{} = tag} = Content.create_tag(%{tag: "Elixir Programming"})
      assert tag.slug == "elixir-programming"
    end

    test "slugifies special characters" do
      assert {:ok, %Tag{} = tag} = Content.create_tag(%{tag: "C++ & Rust!"})
      assert tag.slug == "c-rust"
    end

    test "with missing tag returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Content.create_tag(%{})
    end

    test "enforces unique slug constraint" do
      assert {:ok, %Tag{}} = Content.create_tag(%{tag: "Elixir"})
      assert {:error, %Ecto.Changeset{} = changeset} = Content.create_tag(%{tag: "Elixir"})
      assert "has already been taken" in errors_on(changeset).slug
    end
  end

  describe "tags and posts relationship" do
    test "a post can have many tags" do
      post = post_fixture()
      tag1 = tag_fixture(%{tag: "Elixir"})
      tag2 = tag_fixture(%{tag: "Phoenix"})
      tag3 = tag_fixture(%{tag: "Programming"})

      Jamiec.Repo.insert_all("posts_tags", [
        %{post_id: post.id, tag_id: tag1.id},
        %{post_id: post.id, tag_id: tag2.id},
        %{post_id: post.id, tag_id: tag3.id}
      ])

      post_with_tags = post |> Jamiec.Repo.preload(:tags)

      assert length(post_with_tags.tags) == 3
      assert tag1 in post_with_tags.tags
      assert tag2 in post_with_tags.tags
      assert tag3 in post_with_tags.tags
    end

    test "a tag can have many posts" do
      tag = tag_fixture(%{tag: "Elixir"})
      post1 = post_fixture(%{title: "Post 1"})
      post2 = post_fixture(%{title: "Post 2"})
      post3 = post_fixture(%{title: "Post 3"})

      Jamiec.Repo.insert_all("posts_tags", [
        %{post_id: post1.id, tag_id: tag.id},
        %{post_id: post2.id, tag_id: tag.id},
        %{post_id: post3.id, tag_id: tag.id}
      ])

      tag_with_posts = tag |> Jamiec.Repo.preload(:posts)

      assert length(tag_with_posts.posts) == 3
      assert post1 in tag_with_posts.posts
      assert post2 in tag_with_posts.posts
      assert post3 in tag_with_posts.posts
    end

    test "deleting a post removes its tag associations" do
      post = post_fixture()
      tag = tag_fixture(%{tag: "Elixir"})

      Jamiec.Repo.insert_all("posts_tags", [
        %{post_id: post.id, tag_id: tag.id}
      ])

      Content.delete_post(post)

      tag_with_posts = tag |> Jamiec.Repo.preload(:posts)
      assert tag_with_posts.posts == []
    end

    test "deleting a tag removes its post associations" do
      post = post_fixture()
      tag = tag_fixture(%{tag: "Elixir"})

      Jamiec.Repo.insert_all("posts_tags", [
        %{post_id: post.id, tag_id: tag.id}
      ])

      Content.delete_tag(tag)

      post_with_tags = post |> Jamiec.Repo.preload(:tags)
      assert post_with_tags.tags == []
    end
  end

  describe "search_tags/1" do
    test "returns tags matching the query" do
      tag_fixture(%{tag: "Elixir"})
      tag_fixture(%{tag: "Elixir Phoenix"})
      tag_fixture(%{tag: "Ruby"})

      results = Content.search_tags("elix")

      assert length(results) == 2
      assert Enum.all?(results, fn t -> String.contains?(String.downcase(t.tag), "elix") end)
    end

    test "returns empty list for empty query" do
      tag_fixture(%{tag: "Elixir"})

      assert Content.search_tags("") == []
      assert Content.search_tags(nil) == []
    end

    test "search is case-insensitive" do
      tag_fixture(%{tag: "Elixir"})

      assert length(Content.search_tags("ELIXIR")) == 1
      assert length(Content.search_tags("elixir")) == 1
    end

    test "limits results to 10" do
      for i <- 1..15, do: tag_fixture(%{tag: "Tag #{i}"})

      results = Content.search_tags("Tag")

      assert length(results) == 10
    end
  end

  describe "get_or_create_tag/1" do
    test "returns existing tag if found" do
      existing = tag_fixture(%{tag: "Elixir"})

      {:ok, tag} = Content.get_or_create_tag("Elixir")

      assert tag.id == existing.id
    end

    test "creates new tag if not found" do
      {:ok, tag} = Content.get_or_create_tag("NewTag")

      assert tag.tag == "NewTag"
      assert tag.slug == "newtag"
    end

    test "trims whitespace from name" do
      {:ok, tag} = Content.get_or_create_tag("  Elixir  ")

      assert tag.tag == "Elixir"
    end
  end

  describe "create_post_with_tags/2" do
    test "creates post with associated tags" do
      tag1 = tag_fixture(%{tag: "Elixir"})
      tag2 = tag_fixture(%{tag: "Phoenix"})

      {:ok, post} =
        Content.create_post_with_tags(
          %{title: "My Post"},
          [tag1.id, tag2.id]
        )

      post_with_tags = post |> Jamiec.Repo.preload(:tags)

      assert length(post_with_tags.tags) == 2
      assert tag1 in post_with_tags.tags
      assert tag2 in post_with_tags.tags
    end

    test "creates post with empty tags" do
      {:ok, post} = Content.create_post_with_tags(%{title: "No Tags"}, [])

      post_with_tags = post |> Jamiec.Repo.preload(:tags)

      assert post_with_tags.tags == []
    end
  end

  describe "update_post_with_tags/3" do
    test "updates post and replaces tags" do
      tag1 = tag_fixture(%{tag: "Elixir"})
      tag2 = tag_fixture(%{tag: "Phoenix"})
      tag3 = tag_fixture(%{tag: "OTP"})

      {:ok, post} =
        Content.create_post_with_tags(
          %{title: "Original"},
          [tag1.id]
        )

      {:ok, updated} =
        Content.update_post_with_tags(
          post,
          %{title: "Updated"},
          [tag2.id, tag3.id]
        )

      updated_with_tags = updated |> Jamiec.Repo.preload(:tags)

      assert updated.title == "Updated"
      assert length(updated_with_tags.tags) == 2
      assert tag2 in updated_with_tags.tags
      assert tag3 in updated_with_tags.tags
      refute tag1 in updated_with_tags.tags
    end

    test "can remove all tags" do
      tag = tag_fixture(%{tag: "Elixir"})

      {:ok, post} =
        Content.create_post_with_tags(
          %{title: "Has Tags"},
          [tag.id]
        )

      {:ok, updated} = Content.update_post_with_tags(post, %{}, [])

      updated_with_tags = updated |> Jamiec.Repo.preload(:tags)

      assert updated_with_tags.tags == []
    end
  end
end
