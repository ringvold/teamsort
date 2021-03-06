defmodule Teamsort.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      TeamsortWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Teamsort.PubSub},
      # Start the Endpoint (http/https)
      TeamsortWeb.Endpoint
      # Start a worker by calling: Teamsort.Worker.start_link(arg)
      # {Teamsort.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Teamsort.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TeamsortWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
