# Exbalance
Exbalance is a rudimentary implementation of a load balancer using Elixir and OTP.

## How it works


## TODO
- [ ] Read config from file
- [ ] Proxy requests with http request body
- [ ] Cookies?
- [ ] Worker statistics
- [ ] Worker pool selection algorithms: round robin, least connections, ip hash
- [ ] Persistance (sticky sessions)
- [ ] SSL Offload option?
- [ ] Server weighting
- [ ] Worker pool updating
- [ ] Error handling

## Development
For aid in development there are ExpressJS based servers that can be ran from ```./dev_pool/index.js```. Simply run ```node ./dev_pool/index.js``` in a terminal window to start a couple worker servers for use in the load balancer.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `exbalance` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:exbalance, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/exbalance](https://hexdocs.pm/exbalance).

