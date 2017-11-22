defmodule Exbalance.Server do
  require Logger

  alias Exbalance.Workers

  def init(default_options) do
    Logger.debug("Initializing load balancer")
    default_options
  end

  def build_forward_request(conn = %Plug.Conn{}, {host, port}) do
    IO.inspect(conn)

    method = conn.method
              |> String.downcase
              |> String.to_atom
    {
      "#{conn.scheme}://#{host}:#{port}#{conn.request_path}?#{conn.query_string}",
      method,
      build_forwarded_headers(conn) ++ conn.req_headers,
      conn.body_params
    }
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

  def call(conn, options) do
    {uri, method, headers, _body} = build_forward_request(conn, Workers.get_worker)

    resp = HTTPoison.request(method, uri, "", headers)

    conn
    |> Plug.Conn.send_resp(resp.status_code, resp.body)
  end
end
