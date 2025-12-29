defmodule JamiecWeb.HomeLive do
  @moduledoc false
  use JamiecWeb, :live_view

  alias Jamiec.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <div id="posts" class="space-y-8">
          <div :for={post <- @posts} id={"post-#{post.id}"} class="border-b border-gray-200 pb-6">
            <h2 class="text-2xl font-bold">{post.title}</h2>
            <p :if={post.description} class="mt-2 text-gray-600">{post.description}</p>
          </div>
          <div :if={@posts == []} class="text-gray-500 text-center py-8">
            No posts yet.
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    posts = Content.list_posts(socket.assigns.current_scope)
    {:ok, assign(socket, posts: posts)}
  end
end
