defmodule FluffySpork.Github do
  use GenServer
  require Logger

  ## Client API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: FluffySpork.Github)
  end

  def get_project_id(server, config) do
    GenServer.call(server, {:get_project_id, config})
  end

  def list_columns(server, project_id) do
    GenServer.call(server, {:list_columns, project_id})
  end

  def create_column(server, project_id, column_name) do
    GenServer.call(server, {:create_column, project_id, column_name})
  end

  def list_issues(server, owner, repo) do
    GenServer.call(server, {:list_issues, owner, repo})
  end

  def list_issues(server, fullname) do
    [owner, repo] = String.split(fullname, "/")
    list_issues(server, owner, repo)
  end

  def list_labels(server, owner, repo) do
    GenServer.call(server, {:list_labels, owner, repo})
  end

  def list_labels(server, fullname) do
    [owner, repo] = String.split(fullname, "/")
    list_labels(server, owner, repo)
  end

  def create_label(server, owner, repo, name, color) do
    GenServer.call(server, {:create_label, owner, repo, %{name: name, color: color}})
  end

  def create_label(server, fullname, name, color) do
    [owner, repo] = String.split(fullname, "/")
    create_label(server, owner, repo, name, color)
  end

  def create_card(server, column_id, issue_id) do
    GenServer.call(server, {:create_card, column_id, %{
     "content_id": issue_id,
     "content_type": "Issue"
    }})
  end

  ## Server Callbacks

  def init(:ok) do
    client = Tentacat.Client.new(Application.get_env(:fluffy_spork, :tentacat_client_opts))
    {:ok, %{client: client}}
  end

  def handle_call({:get_project_id, %{owner: owner, repo: repo, number: number}}, _from, state) do
    Tentacat.Projects.list_repos(owner, repo, Map.fetch!(state, :client))
    |> handle_get_project_id(number, state)
  end

  def handle_call({:get_project_id, %{org: org, number: number}}, _from, state) do
    project = Tentacat.Projects.list_orgs(org, Map.fetch!(state, :client))
    |> handle_get_project_id(number, state)
  end

  def handle_call({:list_columns, project_id}, _from, state) do
    columns = Tentacat.Projects.Columns.list(project_id, Map.fetch!(state, :client))
    {:reply, columns, state}
  end

  def handle_call({:create_column, project_id, column_name}, _from, state) do
    Logger.info("Adding column #{column_name} to project #{project_id}.")
    {201, _} = Tentacat.Projects.Columns.create(project_id, column_name, Map.fetch!(state, :client))
    {:reply, :ok, state}
  end

  def handle_call({:list_issues, owner, repo}, _from, state) do
    issues = Tentacat.Issues.list(owner, repo, Map.fetch!(state, :client))
    {:reply, issues, state}
  end

  def handle_call({:list_labels, owner, repo}, _from, state) do
    labels = Tentacat.Repositories.Labels.list(owner, repo, Map.fetch!(state, :client))
    {:reply, labels, state}
  end

  def handle_call({:create_label, owner, repo, body}, _from, state) do
    {201, _} = Tentacat.Repositories.Labels.create(owner, repo, body, Map.fetch!(state, :client))
    {:reply, :ok, state}
  end

  def handle_call({:create_card, column_id, body}, _from, state) do
    {201, _} = Tentacat.Projects.Cards.create(column_id, body, Map.fetch!(state, :client))
    {:reply, :ok, state}
  end

  ## Helpers

  defp handle_get_project_id(projects, number, state) do
    project_id = projects
    |> Enum.find(fn
      %{"number" => ^number} -> true
      _ -> false
    end)
    |> case do
      %{"id" => id} -> id
      _ -> nil
    end
    {:reply, project_id, state}
  end
end
