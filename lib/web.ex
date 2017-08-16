defmodule ChromeRemoteInterface.HTTP do
  def list(server) do
    server
    |> build_request("/json/list")
    |> execute_request()
    |> handle_request()
  end

  def new(server) do
    server
    |> build_request("/json/new")
    |> execute_request()
    |> handle_request()
  end

  def activate(server, id) do
    server
    |> build_request("/json/activate/#{id}")
    |> execute_request()
    |> handle_request()
  end

  def close(server, id) do
    server
    |> build_request("/json/close/#{id}")
    |> execute_request()
    |> handle_request()
  end

  def version(server) do
    server
    |> build_request("/json/version")
    |> execute_request()
    |> handle_request()
  end

  # ---
  # Private
  # ---

  defp http_url(server, path) do
    "http://#{server.host}:#{server.port}#{path}"
  end

  defp build_request(server, path) do
    HTTPipe.Conn.new()
    |> HTTPipe.Conn.put_req_url(http_url(server, path))
    |> HTTPipe.Conn.put_req_method(:get)
  end

  defp execute_request(conn) do
    HTTPipe.Conn.execute(conn)
  end

  defp handle_request({:ok, conn}) do
    with true <- conn.response.status_code >= 200 && conn.response.status_code < 300,
    {:ok, json} <- format_body(conn.response.body) |> Poison.decode() do
      {:ok, json}
    else
      error -> error
    end
  end

  defp handle_request({:error, _} = error) do
    error
  end

  defp format_body(""), do: "{}"
  defp format_body(body), do: body
end
