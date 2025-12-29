defmodule Jamiec.Repo do
  use Ecto.Repo,
    otp_app: :jamiec,
    adapter: Ecto.Adapters.Postgres
end
