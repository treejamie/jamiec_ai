defmodule JamiecWeb.HomeLive do
  @moduledoc false
  use JamiecWeb, :live_view

  alias Jamiec.Content
  alias JamiecWeb.Layouts

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <%!-- Hero Section --%>
      <section class="bg-white px-4 sm:px-6 lg:px-16 py-16 md:py-32">
        <div class="max-w-7xl mx-auto">
          <div class="flex flex-col md:flex-row items-start justify-between gap-8">
            <div class="flex-1">
              <h1 class="text-6xl md:text-8xl font-bold text-[#292f37] tracking-tight mb-8">
                Jamie Curle
              </h1>
              <p class="text-2xl md:text-4xl text-[#989797] max-w-2xl leading-relaxed">
                Technical Leader / Engineer specialising in Elixir, privacy engineering, and security-first systems. Part-time arborist and aspiring woodsman.
              </p>
            </div>
            <div class="flex gap-6 shrink-0">
              <a
                href="https://linkedin.com/in/jamiecurle"
                target="_blank"
                rel="noopener noreferrer"
                class="block"
              >
                <img src={~p"/images/linkedin.svg"} alt="LinkedIn" class="w-24 h-24 md:w-32 md:h-32" />
              </a>
              <a
                href="https://github.com/treejamie"
                target="_blank"
                rel="noopener noreferrer"
                class="block text-[#292f37]"
              >
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 24 24"
                  fill="currentColor"
                  class="w-24 h-24 md:w-32 md:h-32"
                >
                  <path d="M12 0C5.374 0 0 5.373 0 12c0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23A11.509 11.509 0 0112 5.803c1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576C20.566 21.797 24 17.3 24 12c0-6.627-5.373-12-12-12z" />
                </svg>
              </a>
            </div>
          </div>
        </div>
      </section>

      <%!-- Posts Section --%>
      <section class="bg-[#292f37] px-4 sm:px-6 lg:px-16 py-16 md:py-32">
        <div class="max-w-7xl mx-auto">
          <div class="flex flex-col md:flex-row gap-12 md:gap-24">
            <div class="md:w-1/3">
              <h2 class="text-6xl md:text-8xl font-bold text-[#f5f5f5] tracking-tight">
                posts
              </h2>
            </div>
            <div class="md:w-2/3 space-y-8">
              <div :for={post <- @posts} id={"post-#{post.id}"} class="space-y-2">
                <.link navigate={~p"/posts/#{post.id}"}>
                  <h3 class="text-2xl md:text-3xl font-bold text-[#f5f5f5] hover:text-primary transition-colors">
                    {post.title}
                  </h3>
                </.link>
                <p :if={post.description} class="text-lg text-[#f5f5f5] opacity-75 mt-2">
                  {post.description}
                </p>
                <div class="flex items-center gap-4 flex-wrap">
                  <p class="text-sm text-[#f5f5f5]">
                    {Calendar.strftime(post.inserted_at, "%d %B %Y")}
                  </p>
                  <div :if={post.tags && post.tags != []} class="flex gap-2 flex-wrap">
                    <span
                      :for={tag <- post.tags}
                      class="px-4 py-1 border rounded-lg text-sm font-medium"
                      style={"border-color: #{tag_color(tag)}; color: #{tag_color(tag)};"}
                    >
                      {tag.tag}
                    </span>
                  </div>
                </div>
              </div>
              <div :if={@posts == []} class="text-[#f5f5f5] opacity-60 py-8">
                No posts yet.
              </div>
            </div>
          </div>
        </div>
      </section>

      <%!-- Timeline Section --%>
      <section class="bg-white px-4 sm:px-6 lg:px-16 py-16 md:py-32">
        <div class="max-w-7xl mx-auto">
          <div class="flex flex-col md:flex-row gap-12 md:gap-24">
            <div class="md:w-1/3">
              <h2 class="text-6xl md:text-8xl font-bold text-[#292f37] tracking-tight">
                timeline
              </h2>
            </div>
            <div class="md:w-2/3 flex items-center justify-center py-12">
              <div class="text-center text-[#989797]">
                <p class="text-lg">Timeline coming soon...</p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>

    <Layouts.flash_group flash={@flash} />
    """
  end

  defp tag_color(tag) do
    case String.downcase(tag.tag) do
      "privacy" -> "#fcb700"
      "engineering" -> "#00d3bb"
      _ -> "#00d3bb"
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    posts = Content.list_posts(socket.assigns.current_scope)
    {:ok, assign(socket, posts: posts)}
  end
end
