import Config

if config_env() == :prod do
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"

  url =
    if System.get_env("FLY_ALLOC_ID") do
      "#{app_name}.fly.dev"
    else
      "localhost"
    end

  config :teamsort, TeamsortWeb.Endpoint,
    server: true,
    url: [host: url, port: 80],
    http: [
      port: String.to_integer(System.get_env("PORT") || "4000"),
    ],
    secret_key_base: secret_key_base
end
