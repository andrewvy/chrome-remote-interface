defmodule ChromeRemoteInterface.PageSessionTest do
  use ExUnit.Case

  alias ChromeRemoteInterface.PageSession

  describe "Event subscriptions" do
    test "Notifies subscribers of events" do
      state = %PageSession{}
      state = subscribe_to_test_event(state)
      fire_test_event(state)

      assert_receive {:chrome_remote_interface, "TestEvent", _}
    end

    test "Can unsubscribe from events" do
      state = %PageSession{}
      state = subscribe_to_test_event(state)

      {:reply, :ok, state} =
        PageSession.handle_call(
          {:unsubscribe, "TestEvent", self()},
          self(),
          state
        )

      fire_test_event(state)

      refute_receive {:chrome_remote_interface, "TestEvent", _}
    end

    test "Can unsubscribe from all events" do
      state = %PageSession{}
      state = subscribe_to_test_event(state)

      {:reply, :ok, state} =
        PageSession.handle_call(
          {:unsubscribe_all, self()},
          self(),
          state
        )

      fire_test_event(state)

      refute_receive {:chrome_remote_interface, "TestEvent", _}
    end
  end

  describe "RPC" do
    test "Can call RPC events" do
      websocket = spawn_fake_websocket()
      from = {make_ref(), self()}

      state = %PageSession{socket: websocket}

      {:noreply, state} =
        PageSession.handle_call({:call_command, "TestCommand", %{}}, from, state)

      assert [{_ref, {:call, _from}}] = state.callbacks
    end

    test "Receiving message for RPC event removes callback" do
      websocket = spawn_fake_websocket()
      from = {self(), make_ref()}

      state = %PageSession{socket: websocket}

      {:noreply, state} =
        PageSession.handle_call({:call_command, "TestCommand", %{}}, from, state)

      assert [{ref, {:call, _from}}] = state.callbacks

      frame = %{"id" => ref, "result" => %{"data" => %{"foo" => "bar"}}} |> Jason.encode!()
      {:noreply, state} = PageSession.handle_info({:message, frame}, state)

      assert [] = state.callbacks
    end
  end

  def subscribe_to_test_event(state) do
    {:reply, :ok, state} =
      PageSession.handle_call(
        {:subscribe, "TestEvent", self()},
        self(),
        state
      )

    state
  end

  def fire_test_event(state) do
    json =
      Jason.encode!(%{
        method: "TestEvent"
      })

    PageSession.handle_info({:message, json}, state)
  end

  def spawn_fake_websocket() do
    spawn_link(fn ->
      receive do
        {:"$websockex_send", from, _frame} -> GenServer.reply(from, :ok)
      end
    end)
  end
end
