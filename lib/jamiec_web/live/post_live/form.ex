defmodule JamiecWeb.PostLive.Form do
  @moduledoc false
  use JamiecWeb, :live_view

  alias Jamiec.Content
  alias Jamiec.Content.Post

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="flex flex-col h-full">
        <.form
          for={@form}
          id="post-form"
          phx-change="validate"
          phx-submit="save"
          class="flex flex-col flex-1 gap-4"
        >
          <div class="flex gap-4 items-end">
            <div class="flex-1">
              <.input
                field={@form[:title]}
                type="text"
                label="Title"
                placeholder="Post title"
                required
              />
            </div>

            <div class="w-40">
              <.input
                field={@form[:status]}
                type="select"
                label="Status"
                options={Enum.map(Post.statuses(), &{String.capitalize(to_string(&1)), &1})}
              />
            </div>

            <button type="submit" class="btn btn-primary" phx-disable-with="Saving...">
              Save
            </button>
          </div>

          <.input
            field={@form[:description]}
            type="text"
            label="Description"
            placeholder="Brief description"
          />

          <div class="flex-1 flex flex-col">
            <.input
              field={@form[:markdown_body]}
              type="textarea"
              label="Content (Markdown)"
              placeholder="Write your post in markdown..."
              class="flex-1 font-mono min-h-96"
            />
          </div>
        </.form>
      </div>
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
