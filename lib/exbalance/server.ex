defmodule Exbalance.Server do
  require Logger

  alias Exbalance.Workers
  alias Exbalance.Worker

  def init(default_options) do
    Logger.debug("Initializing load balancer")
    default_options
  end

  def build_forward_request(conn = %Plug.Conn{}, %Worker{host: host, port: port}) do
    IO.inspect(conn)

    method = conn.method
              |> String.downcase
              |> String.to_atom
    query_string = if conn.query_string != nil
                    && String.length(conn.query_string) > 0 do
      "?#{conn.query_string}"
    else
      nil
    end

    # TODO(lnw) parse body correctly
    {"#{conn.scheme}://#{host}:#{port}#{conn.request_path}#{query_string}",
      method,
      build_forwarded_headers(conn) ++ conn.req_headers,
      ""}
  end

  def build_forwarded_headers(conn = %Plug.Conn{}) do
    client_ip = conn.remote_ip
                  |> Tuple.to_list
                  |> Enum.join(".")

    [{"X-Forwarded-For", client_ip},
      {"X-Forwarded-Scheme", Atom.to_string(conn.scheme)},
      {"X-Forwarded-Host", conn.host},
      {"X-Forwarded-Port", conn.port}]
  end

  def call(conn, _options) do
    {upstream_uri, method, upstream_headers, upstream_body} =
      build_forward_request(conn, Workers.get_current_worker())

    Logger.debug(fn() -> "Sending request to: #{upstream_uri}" end)

    {status, body} = with {:ok, resp} <-
      HTTPoison.request(method, upstream_uri, upstream_body, upstream_headers) do
        Logger.debug(fn() -> "Response received from #{upstream_uri}" end)
        {resp.status_code, resp.body}
    else
      {:error, err} ->
        Logger.error(fn () -> {"Could not send request to #{upstream_uri}", [additional: err]} end)
        {500, ""}
    end

    conn
    |> Plug.Conn.send_resp(status, body)
  end
end
