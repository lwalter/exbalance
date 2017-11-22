defmodule Exbalance.Workers do

  @config %{
    port: 4040,
    workers: [
      [host: "127.0.0.1", port: 8080],
      [host: "127.0.0.1", port: 8081]
    ]
  }



  def get_config do
    @config
  end

  def get_worker do
    worker = Enum.at(@config.workers, 0)
    {worker[:host], worker[:port]}
  end
end
