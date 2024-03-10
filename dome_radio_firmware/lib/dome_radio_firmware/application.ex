defmodule DomeRadioFirmware.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DomeRadioFirmware.Supervisor]

    children =
      [
        %{
          id: DomeRadioFirmware.InputDriverOne,
          start:
            {DomeRadioFirmware.Inputs, :start_link,
             [%{spi: "spidev0.0", channels: Enum.to_list(0..7)}]}
        },
        %{
          id: DomeRadioFirmware.InputDriverTwo,
          start:
            {DomeRadioFirmware.Inputs, :start_link,
             [%{spi: "spidev0.1", channels: Enum.to_list(7..15)}]}
        }
      ] ++ children(target())

    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  def children(:host) do
    [
      # Children that only run on the host
      # Starts a worker by calling: DomeRadioFirmware.Worker.start_link(arg)
      # {DomeRadioFirmware.Worker, arg},
    ]
  end

  def children(_target) do
    [
      # Children for all targets except host
      # Starts a worker by calling: DomeRadioFirmware.Worker.start_link(arg)
      # {DomeRadioFirmware.Worker, arg},
    ]
  end

  def target() do
    Application.get_env(:dome_radio_firmware, :target)
  end
end
