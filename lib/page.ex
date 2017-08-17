defmodule ChromeRemoteInterface.PageSession do
  require Logger
  use GenServer

  defstruct [
    url: "",
    socket: nil,
    callbacks: [],
    ref_id: 1
  ]

  def start_link(url) do
    GenServer.start_link(__MODULE__, url)
  end

  def execute_command(pid, method, params) do
    GenServer.call(pid, {:execute_command, method, params})
  end

  def init(url) do
    {:ok, socket} = ChromeRemoteInterface.Websocket.start_link(url)
    state = %__MODULE__{
      url: url,
      socket: socket
    }

    {:ok, state}
  end

  def handle_call({:execute_command, method, params}, from, state) do
    message = %{
      "id" => state.ref_id,
      "method" => method,
      "params" => params
    }

    json = Poison.encode!(message)
    WebSockex.send_frame(state.socket, {:text, json})

    new_state =
      state
      |> Map.update(:callbacks, [{state.ref_id, from}], fn(callbacks) ->
        [{state.ref_id, from} | callbacks]
      end)
      |> Map.update(:ref_id, 1, &(&1 + 1))

    {:noreply, new_state}
  end

  def handle_info({:message, frame_data}, state) do
    json = Poison.decode!(frame_data)
    error = json["error"]
    id = json["id"]

    if error do
      Logger.error(error["message"])
    else
      Enum.find(state.callbacks, fn({ref_id, _from}) ->
        ref_id == id
      end)
      |> case do
        {_ref_id, from} -> GenServer.reply(from, json)
        _ -> :ok
      end
    end

    {:noreply, state}
  end
end
