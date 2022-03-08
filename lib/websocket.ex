defmodule ChromeRemoteInterface.Websocket do
  require Logger

  use WebSockex

  def start_link(url) do
    WebSockex.start_link(url, __MODULE__, self())
  end

  def handle_frame({:text, frame_data}, state) do
    send(state, {:message, frame_data})
    {:ok, state}
  end

  def handle_disconnect(_status, state) do
    Process.exit(state, :remote_closed)
    {:ok, state}
  end

  def terminate({:remote, :closed}, _state) do
    :stop
  end
end
