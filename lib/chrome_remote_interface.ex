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
        params = List.wrap(command["parameters"])
        arity = Enum.count(params)
        args = Enum.map(params, &(Macro.var(:"#{&1["name"]}", __MODULE__)))

        @doc description
        if arity > 0 do
          def unquote(:"#{name}")(unquote_splicing(args)), do: "test"
        else
          def unquote(:"#{name}")(), do: "test"
        end
      end
    end
  end)
end
