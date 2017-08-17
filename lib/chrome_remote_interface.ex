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
        def unquote(:"#{name}")(page_pid, args \\ %{}) do
          page_pid |> ChromeRemoteInterface.PageSession.execute_command(
             unquote("#{domain["domain"]}.#{name}"),
             args
           )
        end
      end
    end
  end)

  def list(server) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/list")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end

  def new(server) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/new")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end

  def activate(server, id) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/activate/#{id}")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end

  def close(server, id) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/close/#{id}")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end

  def version(server) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/version")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end
end
