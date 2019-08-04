defmodule ChromeRemoteInterface do
  @moduledoc """
  Documentation for ChromeRemoteInterface.
  """

  alias ChromeRemoteInterface.PageSession

  @protocol_env_key "CRI_PROTOCOL_VERSION"
  @protocol_versions ["1-2", "1-3", "tot"]
  @protocol_version (if (vsn = System.get_env(@protocol_env_key)) in @protocol_versions do
                       vsn
                     else
                       "1-3"
                     end)
  IO.puts(
    "Compiling ChromeRemoteInterface with Chrome DevTools Protocol version: '#{@protocol_version}'"
  )

  @doc """
  Gets the current version of the Chrome Debugger Protocol
  """
  def protocol_version() do
    @protocol_version
  end

  protocol =
    File.read!("priv/#{@protocol_version}/protocol.json")
    |> Jason.decode!()

  # Generate ChromeRemoteInterface.RPC Modules

  Enum.each(protocol["domains"], fn domain ->
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
          |> Enum.map(fn param ->
            "#{param["name"]} - <#{param["$ref"] || param["type"]}> - #{param["description"]}"
          end)

        @doc """
        #{description}

        Parameters:
        #{arg_doc}
        """
        def unquote(:"#{name}")(page_pid) do
          page_pid
          |> PageSession.execute_command(
            unquote("#{domain["domain"]}.#{name}"),
            %{},
            []
          )
        end

        def unquote(:"#{name}")(page_pid, parameters) do
          page_pid
          |> PageSession.execute_command(
            unquote("#{domain["domain"]}.#{name}"),
            parameters,
            []
          )
        end

        def unquote(:"#{name}")(page_pid, parameters, opts) when is_list(opts) do
          page_pid
          |> PageSession.execute_command(
            unquote("#{domain["domain"]}.#{name}"),
            parameters,
            opts
          )
        end
      end
    end
  end)
end
