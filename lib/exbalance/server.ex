defmodule Exbalance.Server do
  require Logger
  #plug Plug.Logger

  alias Exbalance.Workers

  def init(default_options) do
    Logger.debug("Initializing load balancer")
    default_options
  end

  def build_forward_request(conn = %Plug.Conn{}, {host, port}) do
    IO.inspect(conn)

    # Query params is being lost
    {
      "#{conn.scheme}://#{host}:#{port}#{conn.request_path}",
      parse_method(conn.method),
      build_forwarded_headers(conn) ++ conn.req_headers,
      conn.body_params
    }
  end

  def build_forwarded_headers(conn = %Plug.Conn{}) do
    client_ip = conn.remote_ip
                  |> Tuple.to_list
                  |> Enum.join(".")

    forwarded_headers = [{"X-Forwarded-For", client_ip},
                        {"X-Forwarded-Scheme", parse_scheme(conn.scheme)},
                        {"X-Forwarded-Host", conn.host},
                        {"X-Forwarded-Port", conn.port}]
  end

  def parse_scheme(:http), do: "http"
  def parse_scheme(:https), do: "https"

  def parse_method("GET"), do: :get
  def parse_method("POST"), do: :post
  def parse_method("DELETE"), do: :delete
  def parse_method("HEAD"), do: :head
  def parse_method("PUT"), do: :put
  def parse_method("CONNECT"), do: :connect
  def parse_method("OPTIONS"), do: :options
  def parse_method("TRACE"), do: :trace
  def parse_method("PATCH"), do: :patch

  def call(conn, options) do
    {uri, method, headers, body} = build_forward_request(conn, Workers.get_worker)

    IO.inspect(uri)
    IO.inspect(method)
    IO.inspect(headers)
    IO.inspect(body)

    # TODO(lnw) error handling
    resp = HTTPoison.request(method, uri, body, headers)

    IO.inspect(resp)


    conn
    |> Plug.Conn.send_resp(200, "hello world")
  end
end
