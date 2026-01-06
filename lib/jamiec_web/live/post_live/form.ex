defmodule JamiecWeb.PostLive.Form do
  @moduledoc false
  use JamiecWeb, :live_view

  alias Jamiec.Content
  alias Jamiec.Content.Post
  alias JamiecWeb.Live.Components.TagInput

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.form
        for={@form}
        id="post-form"
        phx-change="validate"
        phx-debounce="1500"
        phx-submit="save"
        class="flex flex-col h-full"
      >
        <fieldset class="fieldset bg-base-200 border-base-300 rounded-box border p-4 flex flex-col flex-1 w-full">
          <legend class="fieldset-legend text-lg">{@page_title}</legend>

          <.input field={@form[:title]} label="Title" placeholder="Post title" required />

          <.input
            field={@form[:status]}
            type="select"
            label="Status"
            options={Enum.map(Post.statuses(), &{String.capitalize(to_string(&1)), &1})}
          />

          <.input
            field={@form[:description]}
            label="Description"
            placeholder="Brief description"
          />

          <.live_component
            module={TagInput}
            id="tag-input"
            selected_tags={@selected_tags}
          />

          <.input
            field={@form[:markdown_body]}
            type="textarea"
            label="Content (Markdown)"
            class="textarea w-full flex-1 font-mono min-h-96"
            placeholder="Write your post in markdown..."
          />

          <div class="mt-4">
            <button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
              Save Post
            </button>
          </div>
        </fieldset>
      </.form>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    post = %Post{}
    changeset = Content.change_post(post)

    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, post)
    |> assign(:selected_tags, [])
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    post = Content.get_post!(id) |> Jamiec.Repo.preload(:tags)
    changeset = Content.change_post(post)

    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, post)
    |> assign(:selected_tags, post.tags)
    |> assign(:form, to_form(changeset))
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Content.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.live_action, post_params)
  end

  @impl true
  def handle_info({:update_tags, tags}, socket) do
    {:noreply, assign(socket, :selected_tags, tags)}
  end

  defp save_post(socket, :new, post_params) do
    tag_ids = parse_tag_ids(post_params)

    case Content.create_post_with_tags(post_params, tag_ids) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully.")
         |> push_navigate(to: ~p"/office/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_post(socket, :edit, post_params) do
    tag_ids = parse_tag_ids(post_params)

    case Content.update_post_with_tags(socket.assigns.post, post_params, tag_ids) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully.")
         |> push_navigate(to: ~p"/office/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp parse_tag_ids(%{"tag_ids" => tag_ids}) when is_list(tag_ids) do
    tag_ids
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.to_integer/1)
  end

  defp parse_tag_ids(_), do: []
end
