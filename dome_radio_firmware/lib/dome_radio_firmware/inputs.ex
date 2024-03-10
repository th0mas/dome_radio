defmodule DomeRadioFirmware.Inputs do
  require Logger

  use GenServer
  import Bitwise

  @impl true
  def init(%{spi: port, channels: channels}) do
    {:ok, spi} = Circuits.SPI.open(port)
    Logger.info(channels)

    channel_state =
      channels
      |> Enum.with_index()
      |> Enum.map(fn {channel, index} -> %{id: channel, value: read_channel(spi, index)} end)

    {:ok, %{spi: spi, channels: channel_state}, 100}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @impl true
  def handle_info(:timeout, %{spi: spi, channels: channels} = state) do
    new_channel_state = poll_inputs(spi, channels)
    {:noreply, %{state | channels: new_channel_state}, 50}
  end

  defp poll_inputs(spi, channels) do
    new_vals = read_all(spi, channels)

    channels
    |> Enum.with_index()
    |> Enum.map(fn {channel, index} -> compare_and_emit(channel, Enum.fetch!(new_vals, index)) end)
  end

  defp read_all(spi, channels) do
    0..length(channels)
    |> Enum.map(&read_channel(spi, &1))
  end

  defp read_channel(spi, channel) do
    # We only use the first 4 bits of the control byte - I think it's easier to shift here?
    channel_encoded = channel <<< 4 ||| 0x80

    # Response is three bytes, we only need the last 10
    {:ok, <<_::size(14), counts::size(10)>>} =
      Circuits.SPI.transfer(spi, <<0x1, channel_encoded, 0x00>>)

    counts
  end

  defp compare_and_emit(channel_state, new_value) do
    mapped_value = Float.round(map_range(new_value, {0, 1023}, {0, 1}), 2)

    # Try and only emit changes
    if channel_state.value != mapped_value do
      GenServer.cast(DomeRadio.Controller, {channel_state.id, mapped_value})
    end

    %{channel_state | value: mapped_value}
  end

  def map_range(x, {in_min, in_max}, {out_min, out_max}) do
    (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  end
end
