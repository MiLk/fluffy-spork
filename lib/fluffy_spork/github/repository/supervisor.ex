defmodule FluffySpork.Github.Repository.Supervisor do
  @moduledoc """
  Supervisor for the Respository GenServer
  """

  use Supervisor

  @name FluffySpork.Github.Repository.Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: @name)
  end

  def start_child(name, config) do
    # List already managed repositories
    children = @name
    |> Supervisor.which_children
    |> Enum.map(&elem(&1, 1))
    |> Enum.map(&Process.info(&1))
    |> Enum.map(&Keyword.get(&1, :registered_name))
    # Generate the name of the child for the new repository
    to_start = FluffySpork.Github.Repository.generate_unique_name(name)
    # Do nothing if already started
    if not Enum.member?(children, to_start) do
      {:ok, _} = Supervisor.start_child(@name, [name, config])
    end
    {:ok}
  end

  def init(:ok) do
    import Supervisor.Spec
    children = [worker(FluffySpork.Github.Repository, [])]
    supervise(children, strategy: :simple_one_for_one)
  end

end
