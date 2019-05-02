# Chrome Remote Interface

[![CircleCI](https://img.shields.io/circleci/project/github/andrewvy/chrome-remote-interface.svg)](https://circleci.com/gh/andrewvy/chrome-remote-interface)

This library provides an Elixir Client to the [Chrome Debugging Protocol](https://chromedevtools.github.io/devtools-protocol/) with
a small layer of abstraction for handling and subscribing to domain events.

Note: This is a super minimal client wrapper around the Chrome Debugging Protocol.

## Installation

Add `:chrome_remote_interface` to your `mix.exs` file!

```elixir
def deps do
  [
    {:chrome_remote_interface, "~> 0.2.0"}
  ]
end
```

### Chrome DevTools Protocol Selection

Chrome Remote Interface generated its API at compile time from the protocol
definition released by the Chrome DevTools Team.
For more info see: [https://chromedevtools.github.io/devtools-protocol/](https://chromedevtools.github.io/devtools-protocol/)

This can be overridden by setting `CRI_PROTOCOL_VERSION` environment variable
to:
* 1-2
* 1-3 * default
* tot

Example:
```
CRI_PROTOCOL_VERSION=1-2 mix compile
CRI_PROTOCOL_VERSION=1-3 mix compile
CRI_PROTOCOL_VERSION=tot mix compile
```

## Usage

> Note: In these examples, it assumes you're already running chrome headless with remote debugging enabled.

```bash
chrome --headless --disable-gpu --remote-debugging-port=9222
```

> Basic API

```elixir
# ChromeRemoteInterface works off by creating a Session to the remote debugging port.
# By default, connects to 'localhost:9222
iex(1)> server = ChromeRemoteInterface.Session.new()
%ChromeRemoteInterface.Server{host: "localhost", port: 9222}

iex(2)> {:ok, pages} = ChromeRemoteInterface.Session.list_page(server)
{:ok,
 [%{"description" => "",
    "devtoolsFrontendUrl" => "/devtools/inspector.html?ws=localhost:9222/devtools/page/d4357ff1-47e8-4e53-8289-fc54089da33e",
    "id" => "d4357ff1-47e8-4e53-8289-fc54089da33e", "title" => "Google",
    "type" => "page", "url" => "https://www.google.com/?gws_rd=ssl",
    "webSocketDebuggerUrl" => "ws://localhost:9222/devtools/page/d4357ff1-47e8-4e53-8289-fc54089da33e"}]}

# Now that we have a list of pages, we can connect to any page by using their 'webSocketDebuggerUrl'
iex(3)> first_page = pages |> List.first()
iex(4)> {:ok, page_pid} = ChromeRemoteInterface.PageSession.start_link(first_page)

# Any methods from https://chromedevtools.github.io/devtools-protocol/1-2/ should be available
# to execute on that Page.

# 'Page.navigate'
iex(5)> ChromeRemoteInterface.RPC.Page.navigate(page_pid, %{url: "https://google.com"})
%{"id" => 1, "result" => %{"frameId" => "95446.1"}}

# 'Page.printToPDF'
iex(6)> ChromeRemoteInterface.RPC.Page.printToPDF(page_pid, %{})
{:ok, %{"id" => 2, "result" => %{"data" => "JVBERi0xLj..."}}}
```
