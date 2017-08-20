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
    event_subscribers: %{},
    ref_id: 1
  ]

  # ---
  # Public API
  # ---

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
  Subscribe to an event.

  Events that get fired will be returned to the subscribed process under the following format:

  ```
  {:chrome_remote_interface, event_name, response}
  ```

  Please note that you must also enable events for that domain!

  Example:

  ```
  iex> ChromeRemoteInterface.RPC.Page.enable(page_pid)
  iex> ChromeRemoteInterface.PageSession.subscribe(page_pid, "Page.loadEventFired")
  iex> ChromeRemoteInterface.RPC.Page.navigate(page_pid, %{url: "https://google.com"})
  iex> flush()
  {:chrome_remote_interface, "Page.loadEventFirst", %{"method" => "Page.loadEventFired",
     "params" => %{"timestamp" => 1012329.888558}}}
  ```
  """
  @spec subscribe(pid(), String.t, pid()) :: any()
  def subscribe(pid, event, subscriber_pid \\ self()) do
    GenServer.call(pid, {:subscribe, event, subscriber_pid})
  end

  @doc """
  Unsubscribes from an event.
  """
  @spec unsubscribe(pid(), String.t, pid()) :: any()
  def unsubscribe(pid, event, subscriber_pid \\ self()) do
    GenServer.call(pid, {:unsubscribe, event, subscriber_pid})
  end

  @doc """
  Unscribes to all events.
  """
  def unsubscribe_all(pid, subscriber_pid \\ self()) do
    GenServer.call(pid, {:unsubscribe_all, subscriber_pid})
  end

  @doc """
  Executes a raw JSON RPC command through Websockets.
  """
  def execute_command(pid, method, params) do
    GenServer.call(pid, {:execute_command, method, params})
  end

  # ---
  # Callbacks
  # ---

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

  # @todo(vy): Subscriber pids that die should be removed from being subscribed
  def handle_call({:subscribe, event, subscriber_pid}, _from, state) do
    new_event_subscribers =
      state
      |> Map.get(:event_subscribers, %{})
      |> Map.update(event, [subscriber_pid], fn(subscriber_pids) ->
        [subscriber_pid | subscriber_pids]
      end)

    new_state = %{state | event_subscribers: new_event_subscribers}

    {:reply, :ok, new_state}
  end

  def handle_call({:unsubscribe, event, subscriber_pid}, _from, state) do
    new_event_subscribers =
      state
      |> Map.get(:event_subscribers, %{})
      |> Map.update(event, [], fn(subscriber_pids) ->
        List.delete(subscriber_pids, subscriber_pid)
      end)

    new_state = %{state | event_subscribers: new_event_subscribers}

    {:reply, :ok, new_state}
  end

  def handle_call({:unsubscribe_all, subscriber_pid}, _from, state) do
    new_event_subscribers =
      state
      |> Map.get(:event_subscribers, %{})
      |> Enum.map(fn({key, subscriber_pids}) ->
        {key, List.delete(subscriber_pids, subscriber_pid)}
      end)
      |> Enum.into(%{})

    new_state = %{state | event_subscribers: new_event_subscribers}

    {:reply, :ok, new_state}
  end

  # This handles websocket frames coming from the websocket connection.
  #
  # If a frame has an ID:
  #   - That means it's for an RPC call, so we will reply to the caller with the response.
  #
  # If the frame is an event:
  #   - Forward the event to any subscribers.
  def handle_info({:message, frame_data}, state) do
    json = Poison.decode!(frame_data)
    id = json["id"]
    method = json["method"]

    # Message is an RPC response
    if id do
      send_rpc_response(state.callbacks, id, json)
    end

    # Message is an Domain event
    if method do
      send_event(state.event_subscribers, method, json)
    end

    {:noreply, state}
  end

  defp send_rpc_response(callbacks, id, json) do
    error = json["error"]

    Enum.find(callbacks, fn({ref_id, _from}) ->
      ref_id == id
    end)
    |> case do
      {_ref_id, from} ->
        status = if error, do: :error, else: :ok
        GenServer.reply(from, {status, json})
      _ -> :ok
    end
  end

  defp send_event(event_subscribers, event_name, json) do
    event = {:chrome_remote_interface, event_name, json}

    pids_subscribed_to_event =
      event_subscribers
      |> Map.get(event_name, [])

    pids_subscribed_to_event
    |> Enum.each(&(send(&1, event)))
  end

  def terminate(_reason, state) do
    Process.exit(state.socket, :kill)
    :stop
  end
end
