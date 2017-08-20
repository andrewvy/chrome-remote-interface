defmodule ChromeRemoteInterface.HTTP do
  @moduledoc """
  This module handles communicating with the DevTools HTTP JSON API.
  """

  @type success_http_response :: {:ok, Map.t}
  @type error_http_response :: {:error, any()}

  @spec call(ChromeRemoteInterface.Server.t, String.t) :: success_http_response | error_http_response
  def call(server, path) do
    server
    |> execute_request(path)
    |> handle_response()
  end

  # ---
  # Private
  # ---

  defp http_url(server, path) do
    "http://#{server.host}:#{server.port}#{path}"
  end

  defp execute_request(server, path) do
    :hackney.request(:get, http_url(server, path), [], <<>>, [])
  end

  defp handle_response({:ok, status_code, _response_headers, client_ref}) do
    with true <- status_code >= 200 && status_code < 300,
      {:ok, body} <- :hackney.body(client_ref),
      {:ok, json} <- format_body(body) |> Poison.decode() do
        {:ok, json}
    else
      error -> error
    end
  end

  defp handle_response({:error, {:closed, _}}) do
    {:error, :unexpected_close}
  end

  defp handle_response({:error, reason}) do
    {:error, reason}
  end

  defp format_body(""), do: "{}"
  defp format_body(body), do: body
end
