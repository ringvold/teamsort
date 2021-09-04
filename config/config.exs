# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :teamsort, TeamsortWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "pThGqHZqFtGTReyhp3JeTNCzQO2exm8IzagohpCrnrTHT04KcEMHlFcSUqVXx9iA",
  render_errors: [view: TeamsortWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Teamsort.PubSub,
  live_view: [signing_salt: "96PXDW+A"]

config :surface, :components, [
  {Surface.Components.Form.ErrorTag, default_translator: {TeamsortWeb.ErrorHelpers, :translate_error}}
]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure esbuild (the version is required)
# config :esbuild,
#   version: "0.12.18",
#   default: [
#     args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
#     cd: Path.expand("../assets", __DIR__),
#     env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
#   ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
