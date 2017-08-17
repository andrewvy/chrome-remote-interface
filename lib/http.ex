defmodule ChromeRemoteInterface.HTTP do
  def http_url(server, path) do
    "http://#{server.host}:#{server.port}#{path}"
  end

  def build_request(server, path) do
    HTTPipe.Conn.new()
    |> HTTPipe.Conn.put_req_url(http_url(server, path))
    |> HTTPipe.Conn.put_req_method(:get)
  end

  def execute_request(conn) do
    HTTPipe.Conn.execute(conn)
  end

  def handle_request({:ok, conn}) do
    with true <- conn.response.status_code >= 200 && conn.response.status_code < 300,
    {:ok, json} <- format_body(conn.response.body) |> Poison.decode() do
      {:ok, json}
    else
      error -> error
    end
  end

  def handle_request({:error, _} = error) do
    error
  end

  # ---
  # Private
  # ---

  defp format_body(""), do: "{}"
  defp format_body(body), do: body
end
