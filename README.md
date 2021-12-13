# ExAlsa

ExAlsa is an ALSA NIF for Elixir. ALSA is Linux's audio sound driver and offers fairly low level access to the sound card. This library provides bindings to write sound to ALSA using Elixir. The ALSA API is notoriously esoteric and poorly documented. At the moment the goal is provide a self-configurable instance of ALSA. This will change due to latency needs, whereby the user will be able to declare the period size, channels, sample rate, etc. Also, at the moment this version only supports writing to soundcards. This project does not use OTP and instead meant for driving low-latency sound. There are plans to support OTP in other EleanorDAW packages, but in the mean time, checkout Karlsson's NIF below. It's excellent.

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

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/ex_alsa](https://hexdocs.pm/ex_alsa).

## Related packages
Check out https://github.com/karlsson/xalsa for an Erlang/Elixir solution using OTP.
