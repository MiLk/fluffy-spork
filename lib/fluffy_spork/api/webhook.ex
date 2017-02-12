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
    %{"id" => issue_id, "number" => number, "labels" => labels} = issue
    %{"id" => repo_id, "owner" => %{"login" => repo_owner}, "name" => repo_name} = repository

    project_config = FluffySpork.Config.get_project_for_repo(%{owner: repo_owner, name: repo_name})
    %{columns: columns, when_opened: when_opened} = project_config

    %{name: destination} = get_destination_column(labels, columns, when_opened)

    # Move issue into destination column
    FluffySpork.Github.Project.generate_unique_name(project_config)
    |> FluffySpork.Github.Project.create_card(destination, issue_id)

    conn
    |> send_resp(204, "")
  end

  defp handle_event(:issues, %{"action" => "labeled"}, conn) do
    conn
    |> send_resp(204, "")
  end

  defp handle_event(:label, _, conn) do
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

  defp get_destination_column([], columns, [issue: issue, pr: _]) do
    columns |> Enum.at(issue)
  end

  defp get_destination_column(labels, columns, when_opened) do
    label_names = labels |> Enum.map(&Map.fetch!(&1, "name"))
    destination = columns |> Enum.find(fn (column) ->
      Map.has_key?(column, :label) and Enum.member?(label_names, Map.fetch!(column, :label))
    end)
    if destination == nil do get_destination_column([], columns, when_opened)
    else destination end
  end
end
