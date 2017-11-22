defmodule Exbalance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @config %{
    port: 4040,
    workers: [
      [host: "127.0.0.1", port: 8080, name: "dev-1"],
      #[host: "127.0.0.1", port: 8081, name: "dev-2"]
    ]
  }

  def test_server_children(:prod), do: []
  def test_server_children(:test), do: []
  def test_server_children(:dev) do
    Logger.debug(fn() -> "Dev environment - creating dev servers for workers" end)
    Enum.map(@config.workers, fn(worker) ->
      Plug.Adapters.Cowboy.child_spec(:http, Exbalance.TestServer, [], [port: worker[:port]])
    end)
  end

  def start(_type, _args) do
    children = [
      {Exbalance.Workers, @config.workers},
      Plug.Adapters.Cowboy.child_spec(:http, Exbalance.Server, [], [port: @config.port])
    ]
    test_servers = test_server_children(Mix.env)

    IO.inspect(test_servers)
    opts = [strategy: :one_for_one, name: Exbalance.Supervisor]
    Supervisor.start_link(children ++ test_servers, opts)
  end
end
