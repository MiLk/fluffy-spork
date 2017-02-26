defmodule FluffySpork.Api.Webhook do
  use Plug.Router
  require Logger

  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :match
  plug :dispatch

  post "/" do
    {code, response} = conn.req_headers
    |> Enum.find_value(&extract_github_event/1)
    |> String.to_atom
    |> handle_event(conn.body_params)
    conn |> send_resp(code, response)
  end

  match _ do conn |> send_resp(404, "") end

  defp extract_github_event({k, v}) when k == "x-github-event" do v end
  defp extract_github_event(_) do nil end

  def send_fake_event(event, params) do
    handle_event(event, params)
  end

  defp handle_event(:ping, _) do {200, "pong"} end

  defp handle_event(:issues, %{"action" => "opened", "issue" => issue, "repository" => repository}) do
    %{"labels" => labels} = issue
    create_card(:issue, repository, issue, labels)
  end

  defp handle_event(:issues, %{"action" => "labeled"}) do {204, ""} end
  defp handle_event(:issues, %{"action" => "closed", "issue" => issue, "repository" => repository}) do
    handle_close(:issue, repository, issue)
  end

  defp handle_event(:pull_request, %{"action" => "opened", "pull_request" => pull_request, "repository" => repository}) do
    labels = []
    create_card(:pr, repository, pull_request, labels)
  end
  defp handle_event(:pull_request, %{"action" => "labeled"}) do {204, ""} end
  defp handle_event(:pull_request, %{"action" => "closed", "pull_request" => pull_request, "repository" => repository}) do
    handle_close(:pr, repository, pull_request)
  end

  defp handle_event(:project_card, %{"action" => "created"}) do {204, ""} end
  defp handle_event(:project_card, %{"action" => "moved"}) do {204, ""} end

  defp handle_event(event, body_params) do
    Logger.error("Unexpected event in #{__MODULE__}: #{event}")
    body_params |> IO.inspect
    {500, "Unexpected event"}
  end

  ## Helpers

  defp get_destination_column([], columns, [issue: issue, pr: _], :issue) do columns |> Enum.at(issue) end
  defp get_destination_column([], columns, [issue: _, pr: pr], :pr) do columns |> Enum.at(pr) end

  defp get_destination_column(labels, columns, when_opened, type) do
    label_names = labels |> Enum.map(&Map.fetch!(&1, "name"))
    destination = columns |> Enum.find(fn (column) ->
      Map.has_key?(column, :label) and Enum.member?(label_names, Map.fetch!(column, :label))
    end)
    if destination == nil do get_destination_column([], columns, when_opened, type)
    else destination end
  end

  defp create_card(type, repository, issue, labels) do
    %{"owner" => %{"login" => repo_owner}, "name" => repo_name} = repository
    %{"id" => issue_id, "number" => number} = issue

    project_config = FluffySpork.Config.get_project_for_repo(%{owner: repo_owner, name: repo_name})
    %{columns: columns, when_opened: when_opened} = project_config

    %{name: destination} = get_destination_column(labels, columns, when_opened, type)

    # Move issue into destination column
    project_server = FluffySpork.Github.Project.generate_unique_name(project_config)
    unless FluffySpork.Github.Project.has_card(project_server, {repo_owner, repo_name, number}) do
      FluffySpork.Github.Project.create_card(project_server, destination, issue_id, type)
    end

    {204, ""}
  end

  defp handle_close(type, repository, issue) do
    %{"owner" => %{"login" => repo_owner}, "name" => repo_name} = repository
    %{"id" => _issue_id, "number" => number} = issue

    project_config = FluffySpork.Config.get_project_for_repo(%{owner: repo_owner, name: repo_name})
    %{columns: columns, when_closed: when_closed} = project_config

    %{name: destination} = get_destination_column([], columns, when_closed, type)

    # Move issue into destination column
    project_server = FluffySpork.Github.Project.generate_unique_name(project_config)
    card_id = FluffySpork.Github.Project.get_card_id(project_server, {repo_owner, repo_name, number})
    if card_id == nil do
      Logger.error("Unable to find the card_id for the issue: #{repo_owner}/#{repo_name}/#{number}")
      {500, "Unable to find the card_id for the issue: #{repo_owner}/#{repo_name}/#{number}"}
    else
      FluffySpork.Github.Project.move_card(project_server, card_id, destination, "top")
      {204, ""}
    end
  end
end
