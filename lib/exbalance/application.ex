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
      [host: "127.0.0.1", port: 8081, name: "dev-2"]
    ]
  }

  def start(_type, _args) do
    children = [
      {Exbalance.Workers, @config.workers},
      {Plug.Adapters.Cowboy, scheme: :http, plug: Exbalance.Server, options: [port: @config.port]}
    ]
    opts = [strategy: :one_for_one, name: Exbalance.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
