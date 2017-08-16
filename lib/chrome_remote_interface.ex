defmodule ChromeRemoteInterface do
  @moduledoc """
  Documentation for ChromeRemoteInterface.
  """

  protocol =
    File.read!("priv/protocol.json")
    |> Poison.decode!()

  @protocol_version "#{protocol["version"]["major"]}.#{protocol["version"]["minor"]}"
  def protocol_version(), do: @protocol_version

  Enum.each(protocol["domains"], fn(domain) ->
    defmodule Module.concat(ChromeRemoteInterface, domain["domain"]) do
      @domain domain
      @moduledoc domain["description"]

      def experimental?(), do: @domain["experimental"]

      for command <- @domain["commands"] do
        name = command["name"]
        description = command["description"]

        @doc description
        def unquote(:"#{name}")(server, args \\ %{}) do
          server |> ChromeRemoteInterface.WebsocketSession.execute_command(
             unquote("#{domain["domain"]}.#{name}"),
             args
           )
        end
      end
    end
  end)

  def new_session(host, port) do
    server = %ChromeRemoteInterface.Server{
      host: host,
      port: port
    }

    {:ok, pages} = ChromeRemoteInterface.HTTP.list(server)
    page = List.first(pages)
    url = page["webSocketDebuggerUrl"]

    ChromeRemoteInterface.WebsocketSession.start_link(url, %{id: 1})
  end
end
