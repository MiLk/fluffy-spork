defmodule FluffySpork.Github.Repository do
  @moduledoc """
  GenServer handling operations against one GitHub repository
  """

  use GenServer
  require Logger

  ## Client API

  def start_link(name, config) do
    GenServer.start_link(
      __MODULE__,
      %{name: name, config: config},
      name: generate_unique_name(name)
    )
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

    # Add missing labels
    add_missing_labels(state)

    # List issues
    issues = FluffySpork.Github.list_issues(FluffySpork.Github, name)

    # Add missing cards for listed issues
    add_missing_cards(issues, state)

    Logger.info("Repository #{name} initialized.")

    {:noreply, Map.put(state, :issues, issues)}
  end

  defp list_labels(name) do
    FluffySpork.Github
    |> FluffySpork.Github.list_labels(name)
    |> Enum.map(&Map.fetch!(&1, "name"))
  end

  defp add_missing_labels(%{name: name, config: config}) do
    labels = list_labels(name)
    config
    |> Map.fetch!(:columns)
    |> Enum.reject(fn (column) ->
      !Map.has_key?(column, :label) or Enum.member?(labels, Map.fetch!(column, :label))
    end)
    |> Enum.each(fn (column) ->
      Logger.info("Creating missing label \"#{column[:label]}\" for #{name}.")
      FluffySpork.Github.create_label(FluffySpork.Github, name, column[:label], column[:color])
    end)
  end

  defp add_missing_cards(issues, %{name: name}) do
    [repo_owner, repo_name] = String.split(name, "/", parts: 2)
    # Send a fake webhook event for each issue to create the missing cards
    issues
    |> Enum.map(fn (issue) -> %{
        "action" => "opened",
        "issue" => issue,
        "repository" => %{"owner" => %{"login" => repo_owner}, "name" => repo_name}
      }
    end)
    |> Enum.each(&FluffySpork.Api.Webhook.send_fake_event(:issues, &1))
  end
end
