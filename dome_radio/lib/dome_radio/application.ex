defmodule DomeRadio.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      DomeRadioWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:dome_radio, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: DomeRadio.PubSub},
      # Start a worker by calling: DomeRadio.Worker.start_link(arg)
      # {DomeRadio.Worker, arg},
      # Start to serve requests, typically the last entry
      DomeRadioWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DomeRadio.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DomeRadioWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
