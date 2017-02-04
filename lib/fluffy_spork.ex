defmodule FluffySpork do
  use Application
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Task.async(&init_projects/0)

    children = [
      # Define workers and child supervisors to be supervised
      # worker(FluffySpork.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FluffySpork.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp init_projects do
    projects_config = Application.get_env(:fluffy_spork, :projects)
    Enum.each(projects_config, &init_project(&1))
    Logger.info("Projects initialized.")
  end

  defp init_project(project_config) do
    project_id = get_project_id(project_config)
    Logger.info("Initializing project #{project_id}.")
    client = Tentacat.Client.new(Application.get_env(:fluffy_spork, :tentacat_client_opts))
    columns = Tentacat.Projects.Columns.list(project_id, client)
    names = Enum.map(columns, &Map.fetch!(&1, "name"))
    to_create = MapSet.difference(MapSet.new(Map.fetch!(project_config, :columns)), MapSet.new(names))
    Enum.each(to_create, &create_column(project_id, &1))
  end

  defp get_project_id(%{org: org, number: number}) do
    projects = fetch_projects(%{org: org})
    url = "https://api.github.com/orgs/#{org}"
    project = Enum.find(projects, fn(p) ->
      case p do
        %{"owner_url" => ^url, "number" => ^number} -> true
        _ -> false
      end
    end)
    Map.fetch!(project, "id")
  end

  defp fetch_projects(%{org: org}) do
    client = Tentacat.Client.new(Application.get_env(:fluffy_spork, :tentacat_client_opts))
    Tentacat.Projects.list_orgs(org, client)
  end

  defp create_column(project_id, column_name) do
    Logger.info("Adding column #{column_name} to project #{project_id}.")
    client = Tentacat.Client.new(Application.get_env(:fluffy_spork, :tentacat_client_opts))
    {201, _} = Tentacat.Projects.Columns.create(project_id, column_name, client)
  end
end
