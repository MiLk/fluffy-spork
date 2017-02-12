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
  %{name: "Backlog"},
  %{name: "Ready", label: "ready", color: "ededed"},
  %{name: "In Progress", label: "in progress", color: "ededed"},
  %{name: "In Review", label: "ready for review", color: "f9d0c4"},
  %{name: "To Deploy", label: "to deploy", color: "128a0c"},
  %{name: "Done"},
]

projects = [%{
  org: "YOUR_ORGANIZATION",
  number: PROJECT_NUMBER,
  when_opened: [issue: 0, pr: 1],
  when_closed: [issue: 5, pr: 4],
  columns: columns
}]

config :fluffy_spork, :projects, projects
```
