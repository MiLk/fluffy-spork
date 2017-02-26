defmodule FluffySpork.Github.Repository do
  use GenServer
  require Logger

  ## Client API

  def start_link(name, config) do
    GenServer.start_link(__MODULE__, %{name: name, config: config}, name: generate_unique_name(name))
  end

  def generate_unique_name(name) do :"repo:#{name}" end

  ## Server Callbacks
  def init(state) do
    GenServer.cast(self(), {:init})
    {:ok, state}
  end

  def handle_cast({:init}, state) do
    %{name: name, config: config} = state
    Logger.info("Initializing repository #{name}.")

    # List current labels
    labels = FluffySpork.Github.list_labels(FluffySpork.Github, name)
    |> Enum.map(&Map.fetch!(&1, "name"))

    # Add missing labels
    Map.fetch!(config, :columns) |> Enum.reject(fn (column) ->
      !Map.has_key?(column, :label) or Enum.member?(labels, Map.fetch!(column, :label))
    end)
    |> Enum.each(fn (column) ->
      Logger.info("Creating missing label \"#{column[:label]}\" for #{name}.")
      FluffySpork.Github.create_label(FluffySpork.Github, name, column[:label], column[:color])
    end)

    issues = FluffySpork.Github.list_issues(FluffySpork.Github, name)

    #TODO move issues in the right column in the project

    {:noreply, Map.put(state, :issues, issues)}
  end
end
