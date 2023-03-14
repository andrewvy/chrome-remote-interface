defmodule ChromeRemoteInterface.Session do
  @moduledoc """
  This module provides an API to the DevTools HTTP API.
  """

  alias ChromeRemoteInterface.{
    HTTP,
    Server
  }

  @default_opts [
    host: "localhost",
    port: 9222
  ]

  @doc """
  Create a new ChromeRemoteInterface.Server to perform HTTP requests to.
  """
  @spec new(keyword()) :: Server.t()
  def new(opts \\ []) do
    merged_opts = Keyword.merge(@default_opts, opts)

    %ChromeRemoteInterface.Server{
      host: Keyword.get(merged_opts, :host),
      port: Keyword.get(merged_opts, :port)
    }
  end

  @doc """
  List all Pages.

  Calls `/json/list`.
  """
  @spec list_pages(Server.t()) :: HTTP.success_http_response() | HTTP.error_http_response()
  def list_pages(server) do
    server
    |> HTTP.call("/json/list")
  end

  @doc """
  Creates a new Page.

  Calls `/json/new`.
  """
  @spec new_page(Server.t()) :: HTTP.success_http_response() | HTTP.error_http_response()
  def new_page(server) do
    server
    |> HTTP.call("/json/new", method: :put)
  end

  @doc """
  documentation needed!

  Calls `/json/activate/:id`.
  """
  @spec activate_page(Server.t(), String.t()) ::
          HTTP.success_http_response() | HTTP.error_http_response()
  def activate_page(server, id) do
    server
    |> HTTP.call("/json/activate/#{id}")
  end

  @doc """
  Closes a Page.

  Calls `/json/close/:id`.
  """
  @spec close_page(Server.t(), String.t()) ::
          HTTP.success_http_response() | HTTP.error_http_response()
  def close_page(server, id) do
    server
    |> HTTP.call("/json/close/#{id}")
  end

  @doc """
  Gets the version of Chrome.

  Calls `/json/version`.
  """
  @spec version(Server.t()) :: HTTP.success_http_response() | HTTP.error_http_response()
  def version(server) do
    server
    |> HTTP.call("/json/version")
  end
end
