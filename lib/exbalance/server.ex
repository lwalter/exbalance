defmodule Exbalance.Server do
  require Logger
  use Plug.Router

  alias Exbalance.Workers
  alias Exbalance.Worker

  plug Plug.Logger
  #plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json],
  #                    pass: ["*/*"],
  #                    json_decoder: Poison
  plug :match
  plug :dispatch

  def build_query_string(query_string) when is_binary(query_string) and byte_size(query_string) > 0, do: "?#{query_string}"
  def build_query_string(_query_string), do: nil

  def build_forward_request(conn = %Plug.Conn{request_path: request_path,
                                      scheme: scheme,
                                      query_string: query_string,
                                      method: method,
                                      req_headers: req_headers},
                            %Worker{host: host, port: port}) do
    method = method
              |> String.downcase
              |> String.to_atom
    query_string = build_query_string(query_string)

    # TODO(lnw) Should we be parsing?
    body = with {:ok, body, _conn} <- read_body(conn) do
      body
    else
      _ -> raise "Could not read request body"
    end

    {"#{scheme}://#{host}:#{port}#{request_path}#{query_string}",
      method,
      build_forwarded_headers(conn) ++ req_headers,
      body}
  end

  def build_forwarded_headers(%Plug.Conn{remote_ip: remote_ip, scheme: scheme, host: host, port: port}) do
    client_ip = remote_ip
                  |> Tuple.to_list
                  |> Enum.join(".")

    [{"X-Forwarded-For", client_ip},
      {"X-Forwarded-Scheme", Atom.to_string(scheme)},
      {"X-Forwarded-Host", host},
      {"X-Forwarded-Port", port}]
  end

  match _ do
    {up_uri, method, up_headers, up_body} =
      build_forward_request(conn, Workers.get_current_worker())

    Logger.info(fn() -> "Sending request to: #{up_uri}" end)

    {status, body} = with {:ok, resp} <-
      HTTPoison.request(method, up_uri, up_body, up_headers) do
        Logger.info(fn() -> "Response received from #{up_uri}" end)
        {resp.status_code, resp.body}
    else
      {:error, err} ->
        Logger.error(fn() -> {"Could not send request to #{up_uri}", [additional: err]} end)
        {500, "Internal server error"}
    end

    conn
    |> Plug.Conn.send_resp(status, body)
  end
end
