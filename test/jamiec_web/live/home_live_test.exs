defmodule JamiecWeb.HomeLiveTest do
  use JamiecWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Jamiec.AccountsFixtures
  import Jamiec.ContentFixtures

  describe "homepage" do
    test "logged in user sees all posts regardless of status", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      draft_post = post_fixture(%{title: "Draft Post", status: :draft})
      published_post = post_fixture(%{title: "Published Post", status: :published})
      hidden_post = post_fixture(%{title: "Hidden Post", status: :hidden})

      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ draft_post.title
      assert html =~ published_post.title
      assert html =~ hidden_post.title
    end

    test "anonymous user sees only published posts", %{conn: conn} do
      _draft_post = post_fixture(%{title: "Draft Post", status: :draft})
      published_post = post_fixture(%{title: "Published Post", status: :published})
      _hidden_post = post_fixture(%{title: "Hidden Post", status: :hidden})

      {:ok, _lv, html} = live(conn, ~p"/")

      refute html =~ "Draft Post"
      assert html =~ published_post.title
      refute html =~ "Hidden Post"
    end

    test "shows empty state when no posts exist", %{conn: conn} do
      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ "No posts yet"
    end

    test "displays post title and description", %{conn: conn} do
      post =
        post_fixture(%{
          title: "My Test Post",
          description: "A wonderful description",
          status: :published
        })

      {:ok, _lv, html} = live(conn, ~p"/")

      assert html =~ post.title
      assert html =~ post.description
    end
  end
end
