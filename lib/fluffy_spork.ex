defmodule FluffySpork do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Task.async(&fetch_projects/0)

    children = [
      # Define workers and child supervisors to be supervised
      # worker(FluffySpork.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FluffySpork.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp create_column(project_id, column_name) do
    client = Tentacat.Client.new(Application.get_env(:fluffy_spork, :tentacat_client_opts))
    {201, _} = Tentacat.Projects.Columns.create(project_id, column_name, client)
    {:ok}
  end

  defp init_project(%{"id" => project_id }) do
    client = Tentacat.Client.new(Application.get_env(:fluffy_spork, :tentacat_client_opts))
    columns = Tentacat.Projects.Columns.list(project_id, client)
    names = Enum.map(columns, &Map.fetch!(&1, "name"))
    to_create = MapSet.difference(MapSet.new(Application.get_env(:fluffy_spork, :columns)), MapSet.new(names))
    Enum.each(to_create, &create_column(project_id, &1))
    {:ok}
  end

  defp init_project(_) do {:error, "No id field found."} end

  defp fetch_projects do
    client = Tentacat.Client.new(Application.get_env(:fluffy_spork, :tentacat_client_opts))
    projects = Tentacat.Projects.list_orgs(Application.get_env(:fluffy_spork, :github_organization), client)
    Enum.each(projects, &init_project/1)
    {:ok}
  end
end
