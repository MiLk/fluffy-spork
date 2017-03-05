defmodule Tentacat.Projects.Columns do
  import Tentacat
  alias Tentacat.Client
  @moduledoc """
  The Project columns API allows to manage project columns.
  """

  @spec list(binary, Client.t) :: Tentacat.response
  def list(project_id, client \\ %Client{}, params \\ [], options \\ []) do
    get "projects/#{project_id}/columns", client, params, options
  end

  @spec create(binary, binary, Client.t) :: Tentacat.response
  def create(project_id, name, client \\ %Client{}) do
    post "projects/#{project_id}/columns", client, %{name: name}
  end
end
