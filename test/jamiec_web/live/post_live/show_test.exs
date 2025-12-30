defmodule JamiecWeb.PostLive.ShowTest do
  use JamiecWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Jamiec.ContentFixtures

  describe "show post" do
    test "displays a published post", %{conn: conn} do
      post =
        post_fixture(%{
          title: "My Published Post",
          description: "A great description",
          markdown_body: "# Hello World",
          status: :published
        })

      {:ok, _lv, html} = live(conn, ~p"/posts/#{post.id}")

      assert html =~ "My Published Post"
      assert html =~ "A great description"
      assert html =~ "Hello World"
    end

    test "displays post without description", %{conn: conn} do
      post =
        post_fixture(%{
          title: "Post Without Description",
          description: nil,
          markdown_body: "Some content",
          status: :published
        })

      {:ok, _lv, html} = live(conn, ~p"/posts/#{post.id}")

      assert html =~ "Post Without Description"
      assert html =~ "Some content"
    end

    test "renders html_body content", %{conn: conn} do
      post =
        post_fixture(%{
          title: "Markdown Post",
          markdown_body: "**bold text** and *italic*",
          status: :published
        })

      {:ok, _lv, html} = live(conn, ~p"/posts/#{post.id}")

      assert html =~ "<strong>"
      assert html =~ "bold text"
      assert html =~ "<em>"
      assert html =~ "italic"
    end
  end
end
