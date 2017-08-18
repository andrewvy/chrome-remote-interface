defmodule ChromeRemoteInterface.PageSession do
  @moduledoc """
  This module is responsible for all things connected to a Page.

  - Spawning a process that manages the websocket connection
  - Handling request/response for RPC calls by maintaining unique message IDs
  - Forwarding Domain events to subscribers.
  """

  use GenServer

  defstruct [
    url: "",
    socket: nil,
    callbacks: [],
    ref_id: 1
  ]

  @doc """
  Connect to a Page's 'webSocketDebuggerUrl'.
  """
  def start_link(%{"webSocketDebuggerUrl" => url}), do: start_link(url)
  def start_link(url) do
    GenServer.start_link(__MODULE__, url)
  end

  @doc """
  Stop the websocket connection to the page.
  """
  def stop(page_pid) do
    GenServer.stop(page_pid)
  end

  @doc """
  Executes a raw JSON RPC command through Websockets.
  """
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

    Enum.find(state.callbacks, fn({ref_id, _from}) ->
      ref_id == id
    end)
    |> case do
      {_ref_id, from} ->
        status = if error, do: :error, else: :ok
        GenServer.reply(from, {status, json})
      _ -> :ok
    end

    {:noreply, state}
  end

  def terminate(_reason, state) do
    Process.exit(state.socket, :kill)
    :stop
  end
end
