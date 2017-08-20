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

      {:reply, :ok, state} = PageSession.handle_call(
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

      {:reply, :ok, state} = PageSession.handle_call(
       {:unsubscribe_all, self()},
       self(),
       state
      )

      fire_test_event(state)

      refute_receive {:chrome_remote_interface, "TestEvent", _}
    end
  end

  def subscribe_to_test_event(state) do
    {:reply, :ok, state} = PageSession.handle_call(
     {:subscribe, "TestEvent", self()},
     self(),
     state
    )

    state
  end

  def fire_test_event(state) do
    json = Poison.encode!(%{
      method: "TestEvent"
    })

    PageSession.handle_info({:message, json}, state)
  end
end
