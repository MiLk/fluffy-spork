defmodule FluffySpork.Github.Project do
  use GenServer
  require Logger

  ## Client API

  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: generate_unique_name(config))
  end

  def generate_unique_name(%{owner: owner, repo: repo, number: number}) do :"project:#{owner}/#{repo}/#{number}" end
  def generate_unique_name(%{org: org, number: number}) do :"project:#{org}/#{number}" end

  def create_card(server, column_name, issue_id, type) when is_bitstring(column_name) do
    GenServer.call(server, {:create_card, column_name, issue_id, type})
  end

  def move_card(server, id, column_id, position) do
    GenServer.call(server, {:move_card, id, column_id, position})
  end

  def has_card(server, issue) do
    GenServer.call(server, {:has_card, issue})
  end

  def get_card_id(server, issue) do
    GenServer.call(server, {:get_card_id, issue})
  end

  ## Server Callbacks

  def init(config) do
    GenServer.cast(self(), {:init})
    {:ok, %{config: config}}
  end

  def handle_cast({:init}, state) do
    %{config: config} = state

    project_id = FluffySpork.Github.get_project_id(FluffySpork.Github, config)
    init_project(project_id, config, state)
  end

  def handle_call({:create_card, column_name, issue_id, type}, _from, state) do
    column_id = Map.fetch!(state, :columns)
    |> Enum.find(fn (c) -> Map.fetch!(c, "name") == column_name end)
    |> Map.fetch!("id")
    # https://platform.github.community/t/a-few-issues-ive-had-with-the-projects-preview-api/531/6
    FluffySpork.Github.create_card(FluffySpork.Github, column_id, issue_id, case type do
      :issue -> "Issue"
      :pr -> "PullRequest"
    end)
    {:reply, :ok, state}
  end

   def handle_call({:move_card, id, column_name, position}, _from, state) do
    column_id = Map.fetch!(state, :columns)
    |> Enum.find(fn (c) -> Map.fetch!(c, "name") == column_name end)
    |> Map.fetch!("id")
    FluffySpork.Github.move_card(FluffySpork.Github, id, column_id, position)
    {:reply, :ok, state}
  end

  def handle_call({:has_card, {owner, name, number}}, _from, state) do
    issues = state |> Map.fetch!(:cards) |> list_issues |> Map.keys
    issue = {String.to_atom(owner), String.to_atom(name), number}
    {:reply, Enum.member?(issues, issue), state}
  end

  def handle_call({:get_card_id, {owner, name, number}}, _from, state) do
    issues = state |> Map.fetch!(:cards) |> list_issues
    issue = {String.to_atom(owner), String.to_atom(name), number}
    {:reply, Map.get(issues, issue), state}
  end

  ## Helpers

  defp init_project(nil, config, state) do
    Logger.error("No project matching given configuration: #{inspect(config)}")
    {:stop, :shutdown, state}
  end

  defp init_project(project_id, config, state) do
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
    cards = columns |> Enum.map(&FluffySpork.Github.list_cards(FluffySpork.Github, &1))

    Map.fetch!(config, :repos)
    |> Enum.each(&FluffySpork.Github.Repository.Supervisor.start_child(&1, config))

    {:noreply, Map.merge(state, %{columns: columns, cards: cards})}
  end

  defp list_issues(cards) do
    cards
    |> List.flatten
    |> Enum.reduce(%{}, fn (%{"id" => id, "content_url" => content_url}, acc) ->
      [owner, name, _, number] = content_url |> String.slice(29..-1) |> String.split("/")
      Map.put(acc, {String.to_atom(owner), String.to_atom(name), String.to_integer(number)}, id)
    end)
  end
end
