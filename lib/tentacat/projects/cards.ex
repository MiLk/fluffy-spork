defmodule Tentacat.Projects.Cards do
  import Tentacat
  alias Tentacat.Client

  @spec create(binary, binary, Client.t) :: Tentacat.response
  def create(column_id, body, client \\ %Client{}) do
    post "projects/columns/#{column_id}/cards", client, body
  end

  @spec list(binary, Client.t) :: Tentacat.response
  def list(column_id, client \\ %Client{}) do
    get "projects/columns/#{column_id}/cards", client
  end
end
