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

  def run do
    Workers.get_config
    |> start_server
    # |> establish_connections
    # |> feed_requests
  end
end
