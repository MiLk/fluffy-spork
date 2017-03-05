defmodule FluffySpork.Api do
  @moduledoc """
  Main entrypoint for the Web API
  """

  use Plug.Router

  plug Plug.Logger
  plug Plug.RequestId
  plug :match
  plug :dispatch

  get "/api/version" do
    {:ok, version} = :application.get_key(:fluffy_spork, :vsn)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Poison.encode!(%{version: to_string(version)}))
  end

  forward "/api/webhook", to: FluffySpork.Api.Webhook

  match _ do
    conn
    |> send_resp(404, "")
  end
end
