defmodule FluffySpork.Config do
  @moduledoc """
  Helper to use the config
  """

  def get_project_for_repo(%{owner: owner, name: name}) do
    :fluffy_spork
    |> Application.get_env(:projects)
    |> Enum.find(fn (config) ->
      config
      |> Map.fetch!(:repos)
      |> Enum.member?("#{owner}/#{name}")
    end)
  end
end
