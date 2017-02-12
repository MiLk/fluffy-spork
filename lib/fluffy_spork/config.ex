defmodule FluffySpork.Config do
  def get_project_for_repo(%{owner: owner, name: name}) do
    Application.get_env(:fluffy_spork, :projects)
    |> Enum.find(fn (config) ->
      Map.fetch!(config, :repos)
      |> Enum.member?("#{owner}/#{name}")
    end)
  end
end
