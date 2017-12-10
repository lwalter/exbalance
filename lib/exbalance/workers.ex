defmodule Exbalance.Workers do
  use GenServer

  defstruct [:active_pool, :current_worker]

  alias __MODULE__
  alias Exbalance.Worker
  alias Exbalance.Request

  require Logger

  def start_link(worker_list) do
    GenServer.start_link(__MODULE__,
                          build_from_worker_list(worker_list), name: __MODULE__)
  end

  defp build_from_worker_list(worker_list) do
    worker_list = Enum.map(worker_list, fn(worker) ->
      %Worker{
        host: worker[:host],
        port: worker[:port]
      }
    end)

    %Workers{
      active_pool: worker_list,
      current_worker: 0
    }
  end

  def build_request(conn = %Plug.Conn{}) do
    GenServer.call(__MODULE__, {:build_request, conn})
  end

  defp get_current_worker(%Workers{
                              current_worker: current_worker,
                              active_pool: active_pool}) do
    Enum.at(active_pool, current_worker)
  end

  defp build_query_string(query_string) when is_binary(query_string) and byte_size(query_string) > 0, do: "?#{query_string}"
  defp build_query_string(_query_string), do: nil

  defp build_forwarded_headers(%Plug.Conn{remote_ip: remote_ip, scheme: scheme, host: host, port: port}) do
    client_ip = remote_ip
                  |> Tuple.to_list
                  |> Enum.join(".")

    [{"X-Forwarded-For", client_ip},
      {"X-Forwarded-Scheme", Atom.to_string(scheme)},
      {"X-Forwarded-Host", host},
      {"X-Forwarded-Port", port}]
  end

  def send_request(request = %Request{}) do
    GenServer.call(__MODULE__, {:send_request, request})
  end

  def handle_call({:build_request, conn = %Plug.Conn{request_path: request_path,
                                            scheme: scheme,
                                            query_string: query_string,
                                            method: method,
                                            req_headers: req_headers}}, _from, state) do
    method = method
              |> String.downcase
              |> String.to_atom
    query_string = build_query_string(query_string)

    # TODO(lnw) Should we be parsing?
    body = with {:ok, body, _conn} <- Plug.Conn.read_body(conn) do
      body
    else
      _ -> raise "Could not read request body"
    end

    %Worker{host: host, port: port} = get_current_worker(state)

    {:reply,
    %Request{
      uri: "#{scheme}://#{host}:#{port}#{request_path}#{query_string}",
      method: method,
      headers: build_forwarded_headers(conn) ++ req_headers,
      body: body
    },
    state}
  end

  def handle_call({:send_request, %Request{
                                    uri: uri,
                                    method: method,
                                    body: body,
                                    headers: headers}
                                  },
                                  _from,
                                  state = %Workers{
                                            current_worker: current_worker,
                                            active_pool: active_pool}) do
    resp = with {:ok, resp} <-
      HTTPoison.request(method, uri, body, headers) do
        Logger.info("Response received from #{uri}")
        IO.inspect(resp)
        {resp.status_code, resp.headers, resp.body}
    else
      {:error, err} ->
        Logger.error({"Could not send request to #{uri}", [additional: err]})
        {500, "Internal server error"}
    end

    new_current_worker = rem(current_worker + 1, Enum.count(active_pool))
    {:reply, resp, %{state | current_worker: new_current_worker}}
  end
end
