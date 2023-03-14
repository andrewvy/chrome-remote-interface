defmodule ChromeRemoteInterface.HTTP do
  @moduledoc """
  This module handles communicating with the DevTools HTTP JSON API.
  """

  @type success_http_response :: {:ok, Map.t()}
  @type error_http_response :: {:error, any()}

  @spec call(ChromeRemoteInterface.Server.t(), String.t(), [method: :get | :put]) ::
          success_http_response | error_http_response
  def call(server, path, opts \\ []) do
    method = Keyword.get(opts, :method, :get)

    server
    |> execute_request(method, path)
    |> handle_response()
  end

  # ---
  # Private
  # ---

  defp http_url(server, path) do
    "http://#{server.host}:#{server.port}#{path}"
  end

  defp execute_request(server, method, path) when method in [:get, :put] do
    :hackney.request(method, http_url(server, path), [], <<>>, path_encode_fun: & &1)
  end

  defp handle_response({:ok, status_code, _response_headers, client_ref}) do
    with true <- status_code >= 200 && status_code < 300,
         {:ok, body} <- :hackney.body(client_ref),
         {:ok, formatted_body} <- format_body(body),
         {:ok, json} <- decode(formatted_body) do
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

  defp format_body(""), do: format_body("{}")
  defp format_body(body), do: {:ok, body}

  defp decode(body) do
    case Jason.decode(body) do
      {:ok, json} -> {:ok, json}
      {:error, _reason} -> {:ok, body}
    end
  end
end
