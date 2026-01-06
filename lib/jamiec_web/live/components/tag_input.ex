defmodule JamiecWeb.Live.Components.TagInput do
  @moduledoc """
  A LiveComponent for selecting and managing tags with autocomplete.
  """
  use JamiecWeb, :live_component

  alias Jamiec.Content

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:query, "")
     |> assign(:suggestions, [])
     |> assign(:show_suggestions, false)}
  end

  @impl true
  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)
     |> assign_new(:selected_tags, fn -> [] end)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="fieldset mb-2">
      <label class="label mb-1">Tags</label>

      <div class="flex flex-wrap gap-2 mb-2">
        <span
          :for={tag <- @selected_tags}
          class="badge badge-primary gap-1"
        >
          {tag.tag}
          <button
            type="button"
            phx-click="remove_tag"
            phx-value-id={tag.id}
            phx-target={@myself}
            class="btn btn-ghost btn-xs p-0 min-h-0 h-auto"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="h-3 w-3" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>
        </span>
      </div>

      <div class="relative">
        <input
          type="text"
          value={@query}
          placeholder="Type to search or add tags..."
          phx-keyup="search"
          phx-target={@myself}
          phx-debounce="200"
          phx-keydown="keydown"
          class="input w-full"
          autocomplete="off"
        />

        <div
          :if={@show_suggestions && (@suggestions != [] || String.length(@query) > 0)}
          class="absolute z-50 w-full mt-1 bg-base-100 border border-base-300 rounded-box shadow-lg max-h-48 overflow-y-auto"
        >
          <ul class="menu menu-sm p-1">
            <li :for={tag <- @suggestions}>
              <button
                type="button"
                phx-click="select_tag"
                phx-value-id={tag.id}
                phx-target={@myself}
                class="w-full text-left"
              >
                {tag.tag}
              </button>
            </li>
            <li :if={@query != "" && !tag_exists?(@suggestions, @query)}>
              <button
                type="button"
                phx-click="create_tag"
                phx-value-name={@query}
                phx-target={@myself}
                class="w-full text-left text-success"
              >
                Create "{@query}"
              </button>
            </li>
          </ul>
        </div>
      </div>

      <input
        :for={tag <- @selected_tags}
        type="hidden"
        name="post[tag_ids][]"
        value={tag.id}
      />
      <input :if={@selected_tags == []} type="hidden" name="post[tag_ids][]" value="" />
    </div>
    """
  end

  @impl true
  def handle_event("search", %{"value" => query}, socket) do
    query = String.trim(query)
    suggestions = filter_suggestions(query, socket.assigns.selected_tags)

    {:noreply,
     socket
     |> assign(:query, query)
     |> assign(:suggestions, suggestions)
     |> assign(:show_suggestions, query != "")}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Enter"}, socket) do
    query = socket.assigns.query

    if String.length(query) > 0 do
      # Check if there's an exact match in suggestions
      exact_match = Enum.find(socket.assigns.suggestions, fn t ->
        String.downcase(t.tag) == String.downcase(query)
      end)

      if exact_match do
        add_tag(socket, exact_match)
      else
        create_and_add_tag(socket, query)
      end
    else
      {:noreply, socket}
    end
  end

  def handle_event("keydown", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_tag", %{"id" => id}, socket) do
    tag = Content.get_tag!(id)
    add_tag(socket, tag)
  end

  @impl true
  def handle_event("create_tag", %{"name" => name}, socket) do
    create_and_add_tag(socket, name)
  end

  @impl true
  def handle_event("remove_tag", %{"id" => id}, socket) do
    id = String.to_integer(id)
    selected_tags = Enum.reject(socket.assigns.selected_tags, &(&1.id == id))

    send(self(), {:update_tags, selected_tags})

    {:noreply,
     socket
     |> assign(:selected_tags, selected_tags)}
  end

  defp add_tag(socket, tag) do
    if Enum.any?(socket.assigns.selected_tags, &(&1.id == tag.id)) do
      {:noreply, socket |> assign(:query, "") |> assign(:show_suggestions, false)}
    else
      selected_tags = socket.assigns.selected_tags ++ [tag]
      send(self(), {:update_tags, selected_tags})

      {:noreply,
       socket
       |> assign(:selected_tags, selected_tags)
       |> assign(:query, "")
       |> assign(:suggestions, [])
       |> assign(:show_suggestions, false)}
    end
  end

  defp create_and_add_tag(socket, name) do
    case Content.get_or_create_tag(name) do
      {:ok, tag} -> add_tag(socket, tag)
      {:error, _} -> {:noreply, socket}
    end
  end

  defp filter_suggestions(query, selected_tags) do
    selected_ids = Enum.map(selected_tags, & &1.id)

    Content.search_tags(query)
    |> Enum.reject(&(&1.id in selected_ids))
  end

  defp tag_exists?(suggestions, query) do
    Enum.any?(suggestions, fn t ->
      String.downcase(t.tag) == String.downcase(query)
    end)
  end
end
