# FluffySpork

Bot managing your GitHub projects

## Configuration

```exs
# config/private.exs

use Mix.Config

config :fluffy_spork, :tentacat_client_opts, %{
  access_token: "YOUR_GITHUB_TOKEN"
}
config :fluffy_spork, :github_organization, "YOUR_ORGANIZATION"
config :fluffy_spork, :columns, [
  "Backlog",
  "Ready",
  "In Progress",
  "In Review",
  "To Deploy",
  "Done"
]
```
