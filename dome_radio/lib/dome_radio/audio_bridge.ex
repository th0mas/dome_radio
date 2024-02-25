defmodule AudioBridge do
  use Rustler,
    otp_app: :dome_radio,
    crate: "audiobridge",
    target: System.get_env("RUSTLER_TARGET")


  def add(_a, _b), do: :erlang.nif_error(:nif_not_loaded)

  def play_sound(), do: :erlang.nif_error(:nif_not_loaded)
end
