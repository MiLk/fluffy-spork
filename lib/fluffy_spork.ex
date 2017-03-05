defmodule FluffySpork do
  @moduledoc """
  Start the application
  """

  use Application
  require Logger

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(FluffySpork.Github, []),
      supervisor(FluffySpork.Github.Repository.Supervisor, []),
      Plug.Adapters.Cowboy.child_spec(:http, FluffySpork.Api, [])
    ]

    projects_children = :fluffy_spork
      |> Application.get_env(:projects)
      |> Enum.map(fn(config) ->
        worker(FluffySpork.Github.Project, [config],
          id: FluffySpork.Github.Project.generate_unique_name(config),
          restart: :transient
        )
      end)

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: FluffySpork.Supervisor]
    Supervisor.start_link(children ++ projects_children, opts)
  end
end
