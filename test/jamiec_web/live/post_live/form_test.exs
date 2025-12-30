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

    test "creates a post and stays on page with flash message", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, lv, _html} = live(conn, ~p"/office/posts/new")

      html =
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

      assert html =~ "Post saved"

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
end
