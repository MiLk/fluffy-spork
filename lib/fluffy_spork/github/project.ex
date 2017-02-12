defmodule FluffySpork.Github.Project do
  use GenServer
  require Logger

  ## Client API

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: generate_unique_name(config))
  end

  def generate_unique_name(%{org: org, number: number}) do :"project:#{org}/#{number}" end

  def create_card(server, column_name, issue_id) when is_bitstring(column_name) do
    GenServer.call(server, {:create_card, column_name, issue_id})
  end

  ## Server Callbacks

  def init(config) do
    GenServer.cast(self(), {:init})
    {:ok, %{config: config}}
  end

  def handle_cast({:init}, state) do
    %{config: config} = state

    project_id = FluffySpork.Github.get_project_id(FluffySpork.Github, config)
    Logger.info("Initializing project #{project_id}.")

    # Fetch the names of existing columns
    created = FluffySpork.Github.list_columns(FluffySpork.Github, project_id)
      |> Enum.map(&Map.fetch!(&1, "name"))

    # Create missing columns
    Map.fetch!(config, :columns)
      |> Enum.map(&Map.fetch!(&1, :name))
      |> Enum.reject(&Enum.member?(created, &1))
      |> Enum.each(&FluffySpork.Github.create_column(FluffySpork.Github, project_id, &1))

    columns = FluffySpork.Github.list_columns(FluffySpork.Github, project_id)
    #TODO list cards

    Map.fetch!(config, :repos)
      |> Enum.each(&FluffySpork.Github.Repository.Supervisor.start_child(&1, config))

    {:noreply, Map.put(state, :columns, columns)}
  end

  def handle_call({:create_card, column_name, issue_id}, _from, state) do
    column_id = Map.fetch!(state, :columns)
    |> Enum.find(fn (c) -> Map.fetch!(c, "name") == column_name end)
    |> Map.fetch!("id")
    FluffySpork.Github.create_card(FluffySpork.Github, column_id, issue_id)
    {:reply, :ok, state}
  end
end
