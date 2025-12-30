defmodule JamiecWeb.PostLive.Show do
  @moduledoc false
  use JamiecWeb, :live_view

  alias Jamiec.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <article class="mx-auto max-w-3xl">
        <header class="mb-8">
          <h1 class="text-3xl font-bold">{@post.title}</h1>
          <p :if={@post.description} class="mt-2 text-lg text-gray-600">{@post.description}</p>
        </header>
        <div class="prose max-w-none">
          {raw(@post.html_body)}
        </div>
      </article>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    post = Content.get_post!(id)
    {:ok, assign(socket, post: post)}
  end
end
