defmodule JamiecWeb.PostLive.IndexTest do
  use JamiecWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Jamiec.AccountsFixtures
  import Jamiec.ContentFixtures

  describe "post index" do
    test "authenticated user can access the post list", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      {:ok, _lv, html} = live(conn, ~p"/office/posts")

      assert html =~ "Posts"
      assert html =~ "New Post"
    end

    test "unauthenticated user is redirected to login", %{conn: conn} do
      assert {:error, redirect} = live(conn, ~p"/office/posts")

      assert {:redirect, %{to: path, flash: flash}} = redirect
      assert path == ~p"/office/log-in"
      assert %{"error" => "You must log in to access this page."} = flash
    end

    test "displays all posts for authenticated user", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      draft_post = post_fixture(%{title: "Draft Post", status: :draft})
      published_post = post_fixture(%{title: "Published Post", status: :published})
      hidden_post = post_fixture(%{title: "Hidden Post", status: :hidden})

      {:ok, _lv, html} = live(conn, ~p"/office/posts")

      assert html =~ draft_post.title
      assert html =~ published_post.title
      assert html =~ hidden_post.title
    end

    test "posts link to edit page", %{conn: conn} do
      user = user_fixture()
      conn = log_in_user(conn, user)

      _post = post_fixture(%{title: "Editable Post"})

      {:ok, lv, _html} = live(conn, ~p"/office/posts")

      assert lv |> element("a", "Editable Post") |> has_element?()
    end
  end
end
