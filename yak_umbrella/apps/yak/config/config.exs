# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :yak,
  ecto_repos: [Yak.Repo]

# Configures the endpoint
config :yak, Yak.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "kjSA6bA7iBJTrUIsyZBE2tk1aZshhf6AWaApKBMSayojyKYweQ5Sh2GY0fQzvrG6",
  render_errors: [view: Yak.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Yak.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
