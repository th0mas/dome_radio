defmodule AudioBridge do
  use Rustler,
    otp_app: :dome_radio,
    crate: "audiobridge",
    target: System.get_env("RUSTLER_TARGET")


  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

  def start(), do: :erlang.nif_error(:nif_not_loaded)

  def play_file(_handles, _file_path),  do: :erlang.nif_error(:nif_not_loaded)

  def set_stream_parameters(_stream, _speed, _volume), do: :erlang.nif_error(:nif_not_loaded)
end
