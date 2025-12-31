defmodule JamiecWeb.PostLive.Show do
  @moduledoc false
  use JamiecWeb, :live_view

  alias Jamiec.Content

  @impl true
  def render(assigns) do
    ~H"""
    <div
      class="min-h-screen lg:grid lg:grid-cols-2"
      style="background: linear-gradient(180deg, #FF0046 0%, #FF7802 100%);"
    >
      <%!-- Left: Title/Description (desktop only) --%>
      <div class="hidden lg:flex text-white p-8 lg:p-12 min-h-screen flex-col justify-start">
        <h1 class="font-semibold" style="font-size: 64px; line-height: 64px;">
          {@post.title}
        </h1>
        <p :if={@post.description} class="mt-4 text-lg lg:text-xl opacity-90">
          {@post.description}
        </p>
      </div>

      <%!-- Right: Content with dark overlay --%>
      <div
        class="p-8 lg:p-12 min-h-screen"
        style="background: rgba(62, 62, 62, 0.30);"
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

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    post = Content.get_post!(id)
    {:ok, assign(socket, post: post)}
  end
end
