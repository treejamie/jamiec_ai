defmodule JamiecWeb.PostLive.ShowTest do
  use JamiecWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Jamiec.ContentFixtures

  alias JamiecWeb.PostLive.Show

  # Helper to generate MDEx-style heading HTML
  defp mdex_heading(level, id, text) do
    ~s(<h#{level}><a href="##{id}" aria-hidden="true" class="anchor" id="#{id}"></a>#{text}</h#{level}>)
  end

  describe "build_toc/1" do
    test "returns empty list for nil" do
      assert Show.build_toc(nil) == []
    end

    test "returns empty list for empty string" do
      assert Show.build_toc("") == []
    end

    test "returns empty list for html without headings" do
      assert Show.build_toc("<p>Just a paragraph</p>") == []
    end

    test "extracts single h2 heading" do
      html = mdex_heading(2, "intro", "Introduction")
      assert Show.build_toc(html) == [%{level: 2, id: "intro", text: "Introduction", children: []}]
    end

    test "extracts multiple h2 headings as flat list" do
      html = """
      #{mdex_heading(2, "intro", "Introduction")}
      <p>Some content</p>
      #{mdex_heading(2, "methods", "Methods")}
      <p>More content</p>
      #{mdex_heading(2, "conclusion", "Conclusion")}
      """

      toc = Show.build_toc(html)

      assert length(toc) == 3
      assert Enum.map(toc, & &1.text) == ["Introduction", "Methods", "Conclusion"]
      assert Enum.all?(toc, &(&1.children == []))
    end

    test "nests h3 under h2" do
      html = """
      #{mdex_heading(2, "intro", "Introduction")}
      #{mdex_heading(3, "background", "Background")}
      #{mdex_heading(3, "goals", "Goals")}
      #{mdex_heading(2, "methods", "Methods")}
      """

      toc = Show.build_toc(html)

      assert length(toc) == 2
      [intro, methods] = toc

      assert intro.text == "Introduction"
      assert length(intro.children) == 2
      assert Enum.map(intro.children, & &1.text) == ["Background", "Goals"]

      assert methods.text == "Methods"
      assert methods.children == []
    end

    test "nests deeply - h2 > h3 > h4" do
      html = """
      #{mdex_heading(2, "main", "Main Section")}
      #{mdex_heading(3, "sub", "Subsection")}
      #{mdex_heading(4, "detail", "Detail")}
      """

      toc = Show.build_toc(html)

      assert length(toc) == 1
      [main] = toc

      assert main.text == "Main Section"
      assert length(main.children) == 1

      [sub] = main.children
      assert sub.text == "Subsection"
      assert length(sub.children) == 1

      [detail] = sub.children
      assert detail.text == "Detail"
      assert detail.children == []
    end

    test "handles complex nesting structure" do
      html = """
      #{mdex_heading(2, "a", "Section A")}
      #{mdex_heading(3, "a1", "A.1")}
      #{mdex_heading(3, "a2", "A.2")}
      #{mdex_heading(4, "a2a", "A.2.a")}
      #{mdex_heading(2, "b", "Section B")}
      #{mdex_heading(3, "b1", "B.1")}
      """

      toc = Show.build_toc(html)

      assert length(toc) == 2

      [section_a, section_b] = toc

      assert section_a.text == "Section A"
      assert length(section_a.children) == 2

      [a1, a2] = section_a.children
      assert a1.text == "A.1"
      assert a1.children == []
      assert a2.text == "A.2"
      assert length(a2.children) == 1
      assert hd(a2.children).text == "A.2.a"

      assert section_b.text == "Section B"
      assert length(section_b.children) == 1
      assert hd(section_b.children).text == "B.1"
    end

    test "ignores h1 headings" do
      html = """
      #{mdex_heading(1, "title", "Title")}
      #{mdex_heading(2, "intro", "Introduction")}
      """

      toc = Show.build_toc(html)

      assert length(toc) == 1
      assert hd(toc).text == "Introduction"
    end
  end

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

    test "displays table of contents with headings", %{conn: conn} do
      post =
        post_fixture(%{
          title: "Post With TOC",
          description: "Testing TOC",
          markdown_body: """
          ## Introduction

          Some intro text.

          ## Methods

          Some methods text.

          ## Conclusion

          Final thoughts.
          """,
          status: :published
        })

      {:ok, _lv, html} = live(conn, ~p"/posts/#{post.id}")

      # TOC should contain links to headings
      assert html =~ ~r/<nav[^>]*>.*Introduction.*<\/nav>/s
      assert html =~ "Methods"
      assert html =~ "Conclusion"
    end

    test "displays nested table of contents", %{conn: conn} do
      post =
        post_fixture(%{
          title: "Post With Nested TOC",
          markdown_body: """
          ## Main Section

          Intro.

          ### Subsection One

          Details.

          ### Subsection Two

          More details.
          """,
          status: :published
        })

      {:ok, _lv, html} = live(conn, ~p"/posts/#{post.id}")

      # Should have nested structure
      assert html =~ "Main Section"
      assert html =~ "Subsection One"
      assert html =~ "Subsection Two"
    end

    test "does not display TOC when no headings present", %{conn: conn} do
      post =
        post_fixture(%{
          title: "Post Without Headings",
          markdown_body: "Just a paragraph without any headings.",
          status: :published
        })

      {:ok, _lv, html} = live(conn, ~p"/posts/#{post.id}")

      # Nav element should not be present (or be empty)
      refute html =~ ~r/<nav[^>]*class="mt-8">/
    end
  end
end
