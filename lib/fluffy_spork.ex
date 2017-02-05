defmodule FluffySpork do
  use Application
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(FluffySpork.Github, []),
      supervisor(FluffySpork.Github.Repository.Supervisor, []),
    ]

    projects_config = Application.get_env(:fluffy_spork, :projects)
    projects_children = Enum.map(projects_config, fn(config) ->
      worker(FluffySpork.Github.Project, [config])
    end)

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FluffySpork.Supervisor]
    Supervisor.start_link(children ++ projects_children, opts)
  end
end
