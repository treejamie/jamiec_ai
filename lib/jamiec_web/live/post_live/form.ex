defmodule JamiecWeb.PostLive.Form do
  @moduledoc false
  use JamiecWeb, :live_view

  alias Jamiec.Content
  alias Jamiec.Content.Post

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
    |> assign(:form, to_form(changeset))
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    post = Content.get_post!(id)
    changeset = Content.change_post(post)

    socket
    |> assign(:page_title, "Edit Post")
    |> assign(:post, post)
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

  defp save_post(socket, :new, post_params) do
    case Content.create_post(post_params) do
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
    case Content.update_post(socket.assigns.post, post_params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully.")
         |> push_navigate(to: ~p"/office/posts")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
