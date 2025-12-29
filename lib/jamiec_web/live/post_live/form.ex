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
          <legend class="fieldset-legend text-lg">New Post</legend>

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
    changeset = Content.change_post(%Post{})
    {:ok, assign(socket, form: to_form(changeset))}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      %Post{}
      |> Content.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"post" => post_params}, socket) do
    case Content.create_post(post_params) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully.")
         |> push_navigate(to: ~p"/")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end
end
