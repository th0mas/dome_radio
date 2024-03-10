defmodule DomeRadio.Controller do
  import Integer
  use GenServer
  import Logger

  require Logger

  @audio_files [
    "1.mp3"
  ]

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(arg) do
    case AudioBridge.start() do
      {:error, _err} ->
        info("Failed to init - retrying")
        Process.sleep(100)
        init(arg)

      result ->
        {:ok, %{handlers: result, streams: init_streams(result)}}
    end
  end

  @impl true
  def handle_cast({input_id, new_value}, state) do
    stream_id = div(input_id, 2)

    state =
      if Map.has_key?(state.streams, stream_id) do
        update_type =
          if is_even(input_id) do
            :volume
          else
            :speed
          end

        update_stream(stream_id, update_type, new_value, state)
      else
        state
      end

    {:noreply, state}
  end

  def update_stream(stream, type, value, %{streams: streams} = state) do
    {_new_val, new_state} =
      Map.get_and_update(streams, stream, fn stream ->
        {stream, change(type, stream, value)}
      end)

    Logger.info(inspect(new_state))

    %{state | streams: new_state}
  end

  defp init_streams(handles) do
    @audio_files
    |> Enum.map(fn file -> Path.join([:code.priv_dir(:dome_radio), "audio", file]) end)
    |> Enum.map(&create_stream(handles, &1))
    |> Enum.with_index()
    |> Map.new(fn {stream, index} -> {index, stream} end)
  end

  defp create_stream(handles, file_path) do
    Logger.info("Creating stream")
    raw_stream = AudioBridge.play_file(handles, file_path)

    %{raw_stream: raw_stream, speed: 1.0, volume: 1.0}
  end

  defp change(:volume, %{raw_stream: raw_stream, speed: speed}, new_volume) do
    volume = map_range(new_volume, {0.0, 1.0}, {0.1, 2.0})
    raw_stream = AudioBridge.set_stream_parameters(raw_stream, speed, volume)

    %{raw_stream: raw_stream, speed: speed, volume: volume}
  end

  defp change(:speed, %{raw_stream: raw_stream, volume: volume}, new_speed) do
    speed = map_range(new_speed, {0.0, 1.0}, {0.1, 2.0})
    raw_stream = AudioBridge.set_stream_parameters(raw_stream, speed, volume)

    %{raw_stream: raw_stream, speed: speed, volume: volume}
  end

  def map_range(x, {in_min, in_max}, {out_min, out_max}) do
    (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  end
end
