defmodule JamiecWeb.PageController do
  use JamiecWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
