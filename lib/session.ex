defmodule ChromeRemoteInterface.Server do
  defstruct [
    :host,
    :port,
    :page_pool_size
  ]
end

defmodule ChromeRemoteInterface.Session do
  use GenServer

  @default_opts [
    host: "localhost",
    port: 9222,
    page_pool_size: 100
  ]

  def start_link(opts \\ []) do
    merged_opts = Keyword.merge(@default_opts, opts)

    server = %ChromeRemoteInterface.Server{
      host: Keyword.get(merged_opts, :host),
      port: Keyword.get(merged_opts, :port),
      page_pool_size: Keyword.get(merged_opts, :page_pool_size)
    }

    GenServer.start_link(__MODULE__, server)
  end

  def checkout_page(pid) do
    GenServer.call(pid, :checkout_page)
  end

  def handle_call(:checkout_page, _from, server) do
    {:ok, pages} = ChromeRemoteInterface.list(server)
    page = List.first(pages)
    url = page["webSocketDebuggerUrl"]
    {:reply, ChromeRemoteInterface.PageSession.start_link(url), server}
  end
end
