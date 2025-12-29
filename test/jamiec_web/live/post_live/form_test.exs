defmodule JamiecWeb.PostLive.FormTest do
  use JamiecWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Jamiec.AccountsFixtures

  alias Jamiec.Content

  describe "new post form" do
    test "authenticated user can access the form", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/office/posts/new")

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
        |> follow_redirect(conn, ~p"/")

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
end
