defmodule FluffySpork.Github.Repository do
  use GenServer
  require Logger

  ## Client API

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{name: name}, name: generate_unique_name(name))
  end

  def generate_unique_name(name) do :"repo:#{name}" end

  ## Server Callbacks
  def init(state) do
    GenServer.cast(self(), {:init})
    {:ok, state}
  end

  def handle_cast({:init}, state) do
    %{name: name} = state
    Logger.info("Initializing repository #{name}.")
    issues = FluffySpork.Github.list_issues(FluffySpork.Github, name)

    #TODO move issues in the right column in the project

    {:noreply, Map.put(state, :issues, issues)}
  end
end
