defmodule Exbalance.Workers do
  use GenServer

  defstruct [:active_pool, :current_worker]

  alias __MODULE__
  alias Exbalance.Worker

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

  def get_current_worker do
    GenServer.call(__MODULE__, :current_worker)
  end

  def handle_call(:current_worker, _from, state = %Workers{
                                            current_worker: current_worker,
                                            active_pool: active_pool}) do
    new_current_worker = rem(current_worker + 1, Enum.count(active_pool))
    {:reply,
      Enum.at(active_pool, current_worker),
      %{state | current_worker: new_current_worker}}
  end
end
