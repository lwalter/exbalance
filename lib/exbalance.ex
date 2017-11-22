defmodule Exbalance do

  alias Exbalance.Workers

  @moduledoc """
  Documentation for Exbalance.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Exbalance.hello
      :world

  """

  def start_server(%{port: port}) do
    Plug.Adapters.Cowboy.http(Exbalance.Server, [], [port: port])
  end

  def start_test_servers(%{workers: []}), do: nil
  def start_test_servers(%{workers: workers}) do
    Enum.each(workers, fn(worker) ->
      Plug.Adapters.Cowboy.http(Exbalance.TestServer, [], [port: worker[:port]])
    end)
  end

  def run do
    config = Workers.get_config

    start_test_servers(config)
    start_server(config)
    # |> establish_connections
    # |> feed_requests
  end
end
