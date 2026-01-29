defmodule JamiecWeb.HealthController do
  use JamiecWeb, :controller

  @doc """
  Health check endpoint for Coolify and other monitoring tools.
  Returns 200 OK if the application is running.
  Optionally checks database connectivity.
  """
  def index(conn, _params) do
    # Basic health check - app is responding
    status = %{
      status: "ok",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    # Optional: Add database check
    status = check_database(status)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(status))
  end

  defp check_database(status) do
    case Ecto.Adapters.SQL.query(Jamiec.Repo, "SELECT 1", []) do
      {:ok, _} ->
        Map.put(status, :database, "connected")

      {:error, _} ->
        Map.put(status, :database, "disconnected")
    end
  rescue
    _ ->
      Map.put(status, :database, "error")
  end
end
