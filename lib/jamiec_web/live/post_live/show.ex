defmodule JamiecWeb.PostLive.Show do
  @moduledoc false
  use JamiecWeb, :live_view

  alias Jamiec.Content

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="post-view"
      phx-hook="TocScrollSync"
      class="min-h-screen lg:flex"
      style="background: linear-gradient(180deg, #FF0046 0%, #FF7802 100%);"
    >
      <%!-- Left column (desktop only) --%>
      <div class="hidden lg:block w-1/2 relative">
        <%!-- Title/Description - scrolls with page --%>
        <div class="text-white p-8 lg:p-12">
          <h1 class="font-semibold" style="font-size: 64px; line-height: 64px;">
            {@post.title}
          </h1>
          <p :if={@post.description} class="mt-4 text-lg lg:text-xl opacity-90">
            {@post.description}
          </p>
        </div>
        <%!-- TOC - starts relative, becomes fixed on scroll --%>
        <nav
          :if={@toc != []}
          class="relative left-0 w-1/2 px-8 lg:px-12 text-white"
          data-toc-nav
        >
          <.toc_list items={@toc} />
        </nav>
      </div>

      <%!-- Right: Content with dark overlay --%>
      <div
        class="p-8 lg:p-12 min-h-screen lg:w-1/2"
        style="background: rgba(62, 62, 62, 0.30);"
        data-toc-content
      >
        <%!-- Mobile header --%>
        <header class="lg:hidden mb-8 text-white">
          <h1 class="text-3xl font-bold">{@post.title}</h1>
          <p :if={@post.description} class="mt-2 text-lg opacity-90">{@post.description}</p>
        </header>

        <div class="prose prose-lg prose-invert max-w-none">
          {raw(@post.html_body)}
        </div>
      </div>
    </div>
    <Layouts.flash_group flash={@flash} />
    """
  end

  defp toc_list(assigns) do
    ~H"""
    <ul class="list-none space-y-1 text-sm">
      <li :for={item <- @items}>
        <a href={"##{item.id}"} class="opacity-70 hover:underline transition-opacity">
          {item.text}
        </a>
        <.toc_list :if={item.children != []} items={item.children} />
      </li>
    </ul>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    post = Content.get_post!(id)
    toc = build_toc(post.html_body)
    {:ok, assign(socket, post: post, toc: toc)}
  end

  @doc """
  Extracts headings from HTML and builds a nested table of contents structure.
  """
  def build_toc(nil), do: []
  def build_toc(""), do: []

  def build_toc(html) do
    html
    |> extract_headings()
    |> nest_headings()
  end

  defp extract_headings(html) do
    # Try MDEx with header_ids first: <h2><a href="#id" id="id"></a>Text</h2>
    with_ids =
      ~r/<h([2-6])><a[^>]*id="([^"]*)"[^>]*><\/a>([^<]*)<\/h\1>/i
      |> Regex.scan(html)
      |> Enum.map(fn [_, level, id, text] ->
        %{level: String.to_integer(level), id: id, text: String.trim(text)}
      end)

    if with_ids != [] do
      with_ids
    else
      # Fallback for headings without IDs: <h2>Text</h2>
      ~r/<h([2-6])>([^<]+)<\/h\1>/i
      |> Regex.scan(html)
      |> Enum.map(fn [_, level, text] ->
        text = String.trim(text)
        %{level: String.to_integer(level), id: slugify(text), text: text}
      end)
    end
  end

  defp slugify(text) do
    text
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end

  defp nest_headings([]), do: []

  defp nest_headings(headings) do
    {nested, _} = nest_headings(headings, 2, [])
    Enum.reverse(nested)
  end

  defp nest_headings([], _current_level, acc), do: {acc, []}

  defp nest_headings([%{level: level} = heading | rest], current_level, acc)
       when level == current_level do
    {children, remaining} = nest_headings(rest, level + 1, [])
    item = Map.put(heading, :children, Enum.reverse(children))
    nest_headings(remaining, current_level, [item | acc])
  end

  defp nest_headings([%{level: level} | _] = headings, current_level, acc)
       when level < current_level do
    {acc, headings}
  end

  defp nest_headings([%{level: level} | _] = headings, current_level, acc)
       when level > current_level do
    {children, remaining} = nest_headings(headings, current_level + 1, [])

    case acc do
      [parent | rest] ->
        updated_parent = Map.update!(parent, :children, &(Enum.reverse(children) ++ &1))
        nest_headings(remaining, current_level, [updated_parent | rest])

      [] ->
        nest_headings(remaining, current_level, Enum.reverse(children))
    end
  end
end
