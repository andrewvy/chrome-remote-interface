defmodule ChromeRemoteInterface.PageSessionTest do
  use ExUnit.Case

  alias ChromeRemoteInterface.PageSession

  test "Notifies subscribers of events" do
    state = %PageSession{}

    {:reply, :ok, state} = PageSession.handle_call(
     {:subscribe, "TestEvent", self()},
     self(),
     state
    )

    json = Poison.encode!(%{
      method: "TestEvent"
    })

    PageSession.handle_info({:message, json}, state)

    assert_receive {:chrome_remote_interface, "TestEvent", _}
  end

  test "Can unsubscribe from events" do
    state = %PageSession{}

    {:reply, :ok, state} = PageSession.handle_call(
     {:subscribe, "TestEvent", self()},
     self(),
     state
    )

    json = Poison.encode!(%{
      method: "TestEvent"
    })

    {:reply, :ok, state} = PageSession.handle_call(
     {:unsubscribe, "TestEvent", self()},
     self(),
     state
   )

    PageSession.handle_info({:message, json}, state)

    refute_receive {:chrome_remote_interface, "TestEvent", _}
  end

  test "Can unsubscribe from all events" do
    state = %PageSession{}

    {:reply, :ok, state} = PageSession.handle_call(
     {:subscribe, "TestEvent", self()},
     self(),
     state
    )

    json = Poison.encode!(%{
      method: "TestEvent"
    })

    {:reply, :ok, state} = PageSession.handle_call(
     {:unsubscribe_all, self()},
     self(),
     state
   )

    PageSession.handle_info({:message, json}, state)

    refute_receive {:chrome_remote_interface, "TestEvent", _}
  end
end
