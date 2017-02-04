# FluffySpork

Bot managing your GitHub projects

## Configuration

```exs
# config/private.exs

use Mix.Config

config :fluffy_spork, :tentacat_client_opts, %{
  access_token: "YOUR_GITHUB_TOKEN"
}

columns = [
  "Backlog",
  "Ready",
  "In Progress",
  "In Review",
  "To Deploy",
  "Done"
]

projects = [%{
  org: "YOUR_ORGANIZATION",
  number: PROJECT_NUMBER,
  columns: columns
}]

config :fluffy_spork, :projects, projects
```
