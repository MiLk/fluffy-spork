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

  defp handle_event(:issues, %{"action" => action, "issue" => issue, "repository" => repository})
    when action == "opened" or action == "closed" or action == "reopened" or action == "labeled" or action == "unlabeled" do
      handle_action(String.to_atom(action), :issue, repository, issue)
  end

  defp handle_event(:pull_request, %{"action" => action, "pull_request" => pull_request, "repository" => repository})
    when action == "opened" or action == "closed" or action == "reopened" or action == "labeled" or action == "unlabeled" do
      handle_action(String.to_atom(action), :pr, repository, pull_request)
  end

  defp handle_event(:project_card, %{
    "action" => "created",
    "project_card" => %{"column_id" => column_id},
    "repository" => %{"owner" => %{"login" => repo_owner}, "name" => repo_name}
  }) do
    FluffySpork.Config.get_project_for_repo(%{owner: repo_owner, name: repo_name})
    |> FluffySpork.Github.Project.generate_unique_name
    |> FluffySpork.Github.Project.refresh(column_id)
    {204, ""}
  end
  defp handle_event(:project_card, %{"action" => "moved"}) do {204, ""} end

  defp handle_event(event, body_params) do
    Logger.error("Unexpected event in #{__MODULE__}: #{event}")
    body_params |> IO.inspect
    {500, "Unexpected event"}
  end

  ## Helpers

  defp get_destination_column([], {_, nil}), do: nil
  defp get_destination_column([], {columns, destination}), do: columns |> Enum.at(destination)
  defp get_destination_column(labels, {columns, default_destination}) do
    label_names = labels |> Enum.map(&Map.fetch!(&1, "name"))
    destination = columns |> Enum.reverse |> Enum.find(fn (column) ->
      Map.has_key?(column, :label) and Enum.member?(label_names, Map.fetch!(column, :label))
    end)
    destination || get_destination_column([], {columns, default_destination})
  end

  defp get_destination_config(project_config, action, type, pr \\ nil)
  defp get_destination_config(project_config, action, _, _)
    when action == :labeled or action == :unlabeled do
    %{columns: columns} = project_config
    {columns, nil}
  end
  defp get_destination_config(project_config, :reopened, type, _) do
    get_destination_config(project_config, :opened, type)
  end
  defp get_destination_config(project_config, :closed, :pr, %{"merged" => true}) do
    get_destination_config(project_config, :merged, :pr)
  end
  defp get_destination_config(project_config, action, type, _) do
    %{columns: columns, destinations: %{^action => %{^type => default_destination}}} = project_config
    {columns, default_destination}
  end

  defp handle_action(action, type, repository, issue) do
    %{"owner" => %{"login" => repo_owner}, "name" => repo_name} = repository
    %{"id" => issue_id, "number" => number} = issue

    project_config = FluffySpork.Config.get_project_for_repo(%{owner: repo_owner, name: repo_name})
    %{name: destination} = get_destination_column(
      Map.get(issue, "labels", []),
      get_destination_config(project_config, action, type, issue)
    )

    do_handle_action(action, FluffySpork.Github.Project.generate_unique_name(project_config),
      {repo_owner, repo_name, number}, destination,
      {issue_id, type})
  end

  defp do_handle_action(:opened, project_server, card, destination, {issue_id, type}) do
    unless FluffySpork.Github.Project.has_card(project_server, card) do
      FluffySpork.Github.Project.create_card(project_server, destination, issue_id, type)
    end
    {204, ""}
  end

  defp do_handle_action(action, project_server, card, destination, _)
  when action == :reopened or action == :closed or action == :labeled or action == :unlabeled do
    card_id = FluffySpork.Github.Project.get_card_id(project_server, card)
    if card_id == nil do
      {repo_owner, repo_name, number} = card
      Logger.error("Unable to find the card_id for the issue: #{repo_owner}/#{repo_name}/#{number}")
      {500, "Unable to find the card_id for the issue: #{repo_owner}/#{repo_name}/#{number}"}
    else
      FluffySpork.Github.Project.move_card(project_server, card_id, destination, "top")
      {204, ""}
    end
  end
end
