defmodule Tentacat.Projects.Cards do
  import Tentacat
  alias Tentacat.Client
  @moduledoc """
  The Project cards API allows to manage project cards.
  """

  @spec list(binary, Client.t) :: Tentacat.response
  def list(column_id, client \\ %Client{}) do
    get "projects/columns/#{column_id}/cards", client
  end

  @spec create(binary, binary, Client.t) :: Tentacat.response
  def create(column_id, body, client \\ %Client{}) do
    post "projects/columns/#{column_id}/cards", client, body
  end

  @spec move(binary, binary, Client.t) :: Tentacat.response
  def move(id, body, client \\ %Client{}) do
    post "projects/columns/cards/#{id}/moves", client, body
  end
end
