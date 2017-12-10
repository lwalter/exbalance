defmodule Exbalance.Server do
  require Logger
  use Plug.Router

  alias Exbalance.Workers

  plug Plug.Logger
  # TODO(lnw) Should we be parsing?
  #plug Plug.Parsers, parsers: [:urlencoded, :multipart, :json],
  #                    pass: ["*/*"],
  #                    json_decoder: Poison
  plug :match
  plug :dispatch

  @spec merge_upstream_headers(%Plug.Conn{}, [{String.t, String.t}])
    :: %Plug.Conn{}
  def merge_upstream_headers(conn = %Plug.Conn{resp_headers: resp_headers}, upstream_headers) do
    Logger.debug("Upstream headers:")
    IO.inspect(upstream_headers)

    Logger.debug("Load balancer headers:")
    IO.inspect(resp_headers)

    %{conn | resp_headers: resp_headers ++ upstream_headers}
  end

  #####################################
  # Catch-all route for request traffic
  #####################################
  match _ do
    Logger.debug("Received request")
    {status, headers, body} = conn
                              |> Workers.build_request
                              |> Workers.send_request

    Logger.debug("===== Conn =====")
    IO.inspect(conn)
    Logger.debug("===== END - Conn =====")

    conn
    |> merge_upstream_headers(headers)
    |> Plug.Conn.send_resp(status, body)
  end
end
