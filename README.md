# Chrome Remote Interface

This library provides an Elixir Client to the [Chrome Debugging Protocol](https://chromedevtools.github.io/devtools-protocol/) with
a small layer of abstraction for Session and Page Pooling management.

## Usage

> Note: In these examples, it assumes you're already running chrome headless with remote debugging enabled.

```bash
chrome --headless --disable-gpu --remote-debugging-port=9222
```

> Basic API

```elixir
# ChromeRemoteInterface works off by creating a Session to the remote debugging port.
# By default, connects to 'localhost:9222
iex(1)> {:ok, server} = ChromeRemoteInterface.Session.start_link()
{:ok, #PID<0.369.0>}

# Other configuration options..
iex(1)> {:ok, server} = ChromeRemoteInterface.Session.start_link([
                          host: "localhost",
                          port: 9223
                        ])
{:ok, #PID<0.369.0>}

# From that Session, we can checkout a Page.
iex(2)> {:ok, page_pid} = ChromeRemoteInterface.Session.checkout_page(server)
{:ok, #PID<0.372.0>}

# Any methods from https://chromedevtools.github.io/devtools-protocol/1-2/ should be available
# to execute on that Page.

# 'Page.navigate'
iex(3)> ChromeRemoteInterface.RPC.Page.navigate(page_pid, %{url: "https://google.com"})
%{"id" => 1, "result" => %{"frameId" => "95446.1"}}

# 'Page.printToPDF'
iex(4)> ChromeRemoteInterface.RPC.Page.printToPDF(page_pid, %{})
{:ok, %{"id" => 2, "result" => %{"data" => "JVBERi0xLj..."}}}
```

## Installation

Add `:chrome_remote_interface` to your `mix.exs` file!

```elixir
def deps do
  [
    {:chrome_remote_interface, "~> 0.0.1"}
  ]
end
```
