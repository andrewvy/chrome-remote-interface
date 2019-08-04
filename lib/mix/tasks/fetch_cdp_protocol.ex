defmodule Mix.Tasks.FetchCdpProtocol do
  @moduledoc """
  Fetches up-to-date versions of all the Chrome Debugger Protocol files.

  These protocol files are stored in the private storage of this library.
  """

  use Mix.Task

  @shortdoc "Fetches up-to-date versions of all the Chrome Debugger Protocol files."

  @protocol_sources %{
    "1-2" => %{
      url:
        "https://raw.githubusercontent.com/ChromeDevTools/debugger-protocol-viewer/master/_data/1-2/protocol.json",
      output: "priv/1-2/protocol.json"
    },
    "1-3" => %{
      url:
        "https://github.com/ChromeDevTools/debugger-protocol-viewer/blob/master/_data/1-3/protocol.json",
      output: "priv/1-3/protocol.json"
    },
    "tot" => %{
      url:
        "https://raw.githubusercontent.com/ChromeDevTools/debugger-protocol-viewer/master/_data/tot/protocol.json",
      output: "priv/tot/protocol.json"
    }
  }

  @temporary_file "protocol.json"

  @impl true
  def run(_) do
    Map.keys(@protocol_sources)
    |> Enum.each(&fetch_protocol/1)
  end

  def fetch_protocol(version) do
    protocol_source = Map.fetch!(@protocol_sources, version)

    cmd!("wget #{protocol_source.url}")
    File.rename(@temporary_file, protocol_source.output)
  end

  defp cmd!(cmd) do
    Mix.shell().info([:magenta, "Running: #{cmd}"])

    exit_status = Mix.shell().cmd(cmd)

    if exit_status != 0 do
      Mix.raise("Non-zero result (#{exit_status}) from command: #{cmd}")
    end
  end
end
