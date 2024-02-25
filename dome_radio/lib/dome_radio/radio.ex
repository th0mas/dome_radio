defmodule DomeRadio.Controller do
  use GenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    handles = AudioBridge.start()
    {:ok, %{"handles" => handles}}
  end


end
