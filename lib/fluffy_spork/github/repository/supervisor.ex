defmodule FluffySpork.Github.Repository.Supervisor do
  use Supervisor

  @name FluffySpork.Github.Repository.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_child(name) do
    import Supervisor.Spec

    child_spec = worker(FluffySpork.Github.Repository, [name])
    Supervisor.start_child(@name, child_spec)
  end

  def init(:ok) do
      supervise([], strategy: :one_for_one)
  end

end
