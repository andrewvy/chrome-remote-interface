defmodule ChromeRemoteInterface do
  @moduledoc """
  Documentation for ChromeRemoteInterface.
  """

  protocol =
    File.read!("priv/protocol.json")
    |> Poison.decode!()

  # Generate ChromeRemoteInterface.RPC Modules

  Enum.each(protocol["domains"], fn(domain) ->
    defmodule Module.concat(ChromeRemoteInterface.RPC, domain["domain"]) do
      @domain domain
      @moduledoc domain["description"]

      def experimental?(), do: @domain["experimental"]

      for command <- @domain["commands"] do
        name = command["name"]
        description = command["description"]
        arg_doc =
          command["parameters"]
          |> List.wrap()
          |> Enum.map(fn(param) ->
            "#{param["name"]} - <#{param["$ref"] || param["type"]}> - #{param["description"]}"
          end)

        @doc """
        #{description}

        Parameters:
        #{arg_doc}
        """
        def unquote(:"#{name}")(page_pid, parameters \\ %{}) do
          page_pid |> ChromeRemoteInterface.PageSession.execute_command(
             unquote("#{domain["domain"]}.#{name}"),
             parameters
           )
        end
      end
    end
  end)

  @protocol_version "#{protocol["version"]["major"]}.#{protocol["version"]["minor"]}"
  @doc """
  Gets the current version of the Chrome Debugger Protocol
  """
  def protocol_version(), do: @protocol_version

  @doc """
  List all Pages.

  Calls `/json/list`.
  """
  def list(server) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/list")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end

  @doc """
  Creates a new Page.

  Calls `/json/new`.
  """
  def new(server) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/new")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end

  @doc """
  <documentation needed>

  Calls `/json/activate/:id`.
  """
  def activate(server, id) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/activate/#{id}")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end


  @doc """
  Closes a Page.

  Calls `/json/close/:id`.
  """
  def close(server, id) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/close/#{id}")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end

  @doc """
  Gets the version of Chrome.

  Calls `/json/version`.
  """
  def version(server) do
    server
    |> ChromeRemoteInterface.HTTP.build_request("/json/version")
    |> ChromeRemoteInterface.HTTP.execute_request()
    |> ChromeRemoteInterface.HTTP.handle_request()
  end
end
