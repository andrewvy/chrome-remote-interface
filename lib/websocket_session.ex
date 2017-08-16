defmodule ChromeRemoteInterface.WebsocketSession do
  require Logger
  use WebSockex

  def start_link(url, state) do
    WebSockex.start_link(url, __MODULE__, state)
  end

  def execute_command(pid, method, params) do
    message = %{
      "id" => 1,
      "method" => method,
      "params" => params
    }

    json = Poison.encode!(message)

    pid |> WebSockex.send_frame({:text, json})
  end

  def handle_frame({:text, frame_data}, state) do
    Logger.info(inspect(frame_data))
    {:ok, Map.put(state, :id, state[:id] + 1)}
  end
end
