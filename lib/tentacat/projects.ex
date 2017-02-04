defmodule Tentacat.Projects do
  import Tentacat
  alias Tentacat.Client
  @moduledoc """
  The Projects API allows to manage projects for organizations and repositories.
  """

  @doc """
  List repositories Projects.

  ## Example

      Tentacat.Projects.list_repos("elixir-lang", "elixir", client)

  More info at: https://developer.github.com/v3/repos/#list-organization-repositories
  """
  @spec list_repos(binary, binary, Client.t) :: Tentacat.response
  def list_repos(owner, repo, client \\ %Client{}, params \\ [], options \\ []) do
    get "repos/#{owner}/#{repo}/projects", client, params, options
  end

  @doc """
  List organizations Projects.

  ## Example

      Tentacat.Projects.list_orgs("elixir-lang", client)

  More info at: https://developer.github.com/v3/repos/#list-organization-repositories
  """
  @spec list_orgs(binary, Client.t) :: Tentacat.response
  def list_orgs(org, client \\ %Client{}, params \\ [], options \\ []) do
    get "orgs/#{org}/projects", client, params, options
  end

end
