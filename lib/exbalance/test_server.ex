defmodule Exbalance.TestServer do
  require Logger

  def init(default_options) do
    default_options
  end

  def call(conn, options) do
    conn
    |> Plug.Conn.send_resp(200, "Hey there from Test Server")
  end
end
