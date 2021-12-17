# ExAlsa

ExAlsa is an ALSA NIF for Elixir. The purpose of this library is provide a low-latency and configurable interface to ALSA. Determinism and minimizing latency are the primary goals of this project, in that order. This NIF runs on BEAM's dirty scheduler. Some experiments are being done to see if it's possible to to write to the soundcard buffer in under a ms, details to come.

One other goal is to provide enough documentation for implementors to configure their own ALSA handler properly for _their_ use case.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_alsa` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_alsa, "~> 0.1.0"}
  ]
end
```

## Usage
```
...
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_alsa](https://hexdocs.pm/ex_alsa).

## Influences/Alternative packages
Check out Mikael Karlsson's excellent https://github.com/karlsson/xalsa for an Erlang/Elixir solution using OTP.
