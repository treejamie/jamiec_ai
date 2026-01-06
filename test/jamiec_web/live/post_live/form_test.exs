defmodule JamiecWeb.PostLive.FormTest do
  use JamiecWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Jamiec.AccountsFixtures
  import Jamiec.ContentFixtures

  alias Jamiec.Content

  describe "new post form" do
    test "authenticated user can access the form", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/office/posts/new")

      assert html =~ "New Post"
      assert html =~ "Title"
      assert html =~ "Status"
      assert html =~ "Description"
      assert html =~ "Content (Markdown)"
      assert html =~ "Save"
    end

    test "unauthenticated user is redirected to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/office/posts/new")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/office/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "creates a post when form is submitted with valid data", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/office/posts/new")

      {:ok, _lv, html} =
        lv
        |> form("#post-form", %{
          "post" => %{
            "title" => "My Test Post",
            "description" => "A test description",
            "markdown_body" => "# Hello\n\nThis is my post.",
            "status" => "published"
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/office/posts")

      assert html =~ "Post created successfully"

      # Verify post was created
      [post] = Content.list_posts(nil)
      assert post.title == "My Test Post"
      assert post.description == "A test description"
      assert post.status == :published
      assert post.html_body =~ "<h1>"
    end

    test "shows validation errors for invalid data", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/office/posts/new")

      html =
        lv
        |> form("#post-form", %{
          "post" => %{
            "title" => "",
            "description" => "Missing title"
          }
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "edit post form" do
    test "authenticated user can access the edit form", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      post = post_fixture(%{title: "Existing Post"})

      {:ok, _lv, html} = live(conn, ~p"/office/posts/#{post.id}/edit")

      assert html =~ "Edit Post"
      assert html =~ "Existing Post"
    end

    test "unauthenticated user is redirected to login", %{conn: conn} do
      post = post_fixture()

      assert {:error, redirect} = live(conn, ~p"/office/posts/#{post.id}/edit")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/office/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "updates a post when form is submitted with valid data", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      post = post_fixture(%{title: "Original Title", status: :draft})

      {:ok, lv, _html} = live(conn, ~p"/office/posts/#{post.id}/edit")

      {:ok, _lv, html} =
        lv
        |> form("#post-form", %{
          "post" => %{
            "title" => "Updated Title",
            "status" => "published"
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/office/posts")

      assert html =~ "Post updated successfully"

      # Verify post was updated
      updated_post = Content.get_post!(post.id)
      assert updated_post.title == "Updated Title"
      assert updated_post.status == :published
    end

    test "shows validation errors for invalid data", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      post = post_fixture()

      {:ok, lv, _html} = live(conn, ~p"/office/posts/#{post.id}/edit")

      html =
        lv
        |> form("#post-form", %{
          "post" => %{
            "title" => ""
          }
        })
        |> render_submit()

      assert html =~ "can&#39;t be blank"
    end
  end

  describe "tag input" do
    test "tag input is displayed on new post form", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/office/posts/new")

      assert html =~ "Tags"
      assert html =~ "Type to search or add tags"
    end

    test "tag input is displayed on edit post form", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      post = post_fixture()

      {:ok, _lv, html} = live(conn, ~p"/office/posts/#{post.id}/edit")

      assert html =~ "Tags"
    end

    test "edit form shows existing tags", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      tag = tag_fixture(%{tag: "Elixir"})

      {:ok, post} = Content.create_post_with_tags(%{title: "Tagged Post"}, [tag.id])

      {:ok, _lv, html} = live(conn, ~p"/office/posts/#{post.id}/edit")

      assert html =~ "Elixir"
    end

    test "creates post with tags via search and select", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      tag = tag_fixture(%{tag: "Phoenix"})

      {:ok, lv, _html} = live(conn, ~p"/office/posts/new")

      # First search to show suggestions
      lv
      |> element("#tag-input input[phx-keyup='search']")
      |> render_keyup(%{"value" => "Phoe"})

      # Select the tag from suggestions
      lv
      |> element("#tag-input [phx-click='select_tag'][phx-value-id='#{tag.id}']")
      |> render_click()

      # Submit the form
      {:ok, _lv, html} =
        lv
        |> form("#post-form", %{
          "post" => %{
            "title" => "Post with Tags",
            "status" => "draft"
          }
        })
        |> render_submit()
        |> follow_redirect(conn, ~p"/office/posts")

      assert html =~ "Post created successfully"

      # Verify post was created with tags
      post =
        Jamiec.Repo.get_by!(Jamiec.Content.Post, title: "Post with Tags")
        |> Jamiec.Repo.preload(:tags)

      assert length(post.tags) == 1
      assert hd(post.tags).tag == "Phoenix"
    end

    test "can search for tags and see suggestions", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)
      tag_fixture(%{tag: "Elixir"})
      tag_fixture(%{tag: "Erlang"})

      {:ok, lv, _html} = live(conn, ~p"/office/posts/new")

      html =
        lv
        |> element("#tag-input input[phx-keyup='search']")
        |> render_keyup(%{"value" => "eli"})

      assert html =~ "Elixir"
      refute html =~ "Erlang"
    end
  end
end
