defmodule DomeRadio.Controller do
  use GenServer
  import Logger

  @audio_files [
    "1.mp3",
    "2.mp3"
  ]

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    send(__MODULE__, {:init})

    {:ok, %{}}
  end

  @impl true
  def handle_info({:init}, state) do
    info("Running init")
    case AudioBridge.start() do
      {:error, _err} ->
        Process.send_after(__MODULE__, {:init}, 100)
        {:noreply, state}

      result ->
        {:noreply, %{handlers: result, streams: init_streams(result)}}
    end
  end

  @impl true
  def handle_cast({:new_value, stream, type, value}, %{streams: streams} = state) do
    new_state =
      Map.get_and_update(streams, stream, fn stream ->
        case type do
          :volume -> change_volume(stream, value)
          :speed -> change_speed(stream, value)
        end
      end)

    {:noreply, %{state | streams: new_state}}
  end

  defp init_streams(handles) do
    @audio_files
    |> Enum.map(fn file -> Path.join([:code.priv_dir(:dome_radio), "audio", file]) end)
    |> Enum.map(&create_stream(handles, &1))
  end

  defp create_stream(handles, file_path) do
    raw_stream = AudioBridge.play_file(handles, file_path)

    %{raw_stream: raw_stream, speed: 1, volume: 1}
  end

  defp change_volume(%{raw_stream: raw_stream, speed: speed}, new_volume) do
    raw_stream = AudioBridge.set_stream_parameters(raw_stream, speed, new_volume)

    %{raw_stream: raw_stream, speed: speed, volume: new_volume}
  end

  defp change_speed(%{raw_stream: raw_stream, volume: volume}, new_speed) do
    raw_stream = AudioBridge.set_stream_parameters(raw_stream, new_speed, volume)

    %{raw_stream: raw_stream, speed: new_speed, volume: volume}
  end
end
