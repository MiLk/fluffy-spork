defmodule FluffySpork.Github.Repository.Supervisor do
  use Supervisor

  @name FluffySpork.Github.Repository.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_child(name, config) do
    {:ok, _} = Supervisor.start_child(@name, [name, config])
  end

  def init(:ok) do
    import Supervisor.Spec
    children = [worker(FluffySpork.Github.Repository, [])]
    supervise(children, strategy: :simple_one_for_one)
  end

end
