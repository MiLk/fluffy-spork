defmodule FluffySpork.Api.Webhook do
  use Plug.Router
  require Logger

  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :match
  plug :dispatch

  post "/" do
    conn.req_headers
    |> Enum.find_value(&extract_github_event/1)
    |> String.to_atom
    |> handle_event(conn.body_params, conn)
  end

  match _ do
    conn
    |> send_resp(404, "")
  end

  defp extract_github_event({k, v}) when k == "x-github-event" do v end
  defp extract_github_event(_) do nil end

  defp handle_event(:ping, _, conn) do
    conn
    |> send_resp(200, "pong")
  end

  defp handle_event(:issues, %{"action" => "opened", "issue" => issue, "repository" => repository}, conn) do
    IO.inspect({issue, repository})
    #TODO handle the new issue
    conn
    |> send_resp(204, "")
  end

  defp handle_event(event, body_params, conn) do
    Logger.error("Unexpected event in #{__MODULE__}: #{event}")
    body_params
    |> IO.inspect
    conn
    |> send_resp(500, "Unexpected event")
  end
end
