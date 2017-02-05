defmodule FluffySpork.Github do
  use GenServer
  require Logger

  ## Client API

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: FluffySpork.Github)
  end

  def get_project_id(server, %{org: org, number: number}) do
    GenServer.call(server, {:get_project_id, %{org: org, number: number}})
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

  ## Server Callbacks

  def init(:ok) do
    client = Tentacat.Client.new(Application.get_env(:fluffy_spork, :tentacat_client_opts))
    {:ok, %{client: client}}
  end

  def handle_call({:get_project_id, %{org: org, number: number}}, _from, state) do
    url = "https://api.github.com/orgs/#{org}"
    project = Tentacat.Projects.list_orgs(org, Map.fetch!(state, :client))
      |> Enum.find(fn
          %{"owner_url" => ^url, "number" => ^number} -> true
          _ -> false
        end)
    {:reply, Map.fetch!(project, "id"), state}
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
end
