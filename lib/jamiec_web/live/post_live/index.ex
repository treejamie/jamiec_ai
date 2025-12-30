defmodule JamiecWeb.PostLive.Index do
  @moduledoc false
  use JamiecWeb, :live_view

  alias Jamiec.Content

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-3xl">
        <div class="flex justify-between items-center mb-6">
          <h1 class="text-2xl font-bold">Posts</h1>
          <.link navigate={~p"/office/posts/new"} class="btn btn-primary">
            New Post
          </.link>
        </div>

        <div id="posts" class="space-y-4">
          <div
            :for={post <- @posts}
            id={"post-#{post.id}"}
            class="flex justify-between items-center border-b border-gray-200 pb-4"
          >
            <div>
              <.link navigate={~p"/office/posts/#{post.id}/edit"} class="font-semibold">
                {post.title}
              </.link>
              <span class={"ml-2 badge #{status_badge_class(post.status)}"}>
                {post.status}
              </span>
            </div>
          </div>
          <div :if={@posts == []} class="text-gray-500 text-center py-8">
            No posts yet.
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp status_badge_class(:draft), do: "badge-warning"
  defp status_badge_class(:published), do: "badge-success"
  defp status_badge_class(:hidden), do: "badge-ghost"

  @impl true
  def mount(_params, _session, socket) do
    posts = Content.list_posts(socket.assigns.current_scope)
    {:ok, assign(socket, posts: posts)}
  end
end
