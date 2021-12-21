# ExAlsa

ExAlsa is an ALSA NIF for Elixir. The purpose of this library is provide a low-latency and configurable interface to ALSA. Writing and capturing sound from devices with as low latency as possible in as deterministic way as possible is the primary goal of this library.

An additional goal is to provide enough documentation for implementors to configure their own ALSA handler properly for _their_ use case and to have some basic understanding of [PCM sound generation](https://en.wikipedia.org/wiki/Pulse-code_modulation).

## Requirements
* Linux >= 2.6

## Installation

```elixir
def deps do
  [
    {:ex_alsa, "~> 0.1.0"}
  ]
end
```

## Usage
```
{:ok, handler} = ExAlsa.open_handler("default")
{:ok, _options} = ExAlsa.set_params(%{
    channels: 1,    
    rate: 44100,
    buffeR_size: 
})

# Stream silence for the length of one buffer size
ExAlsa.write(List.duplicate(0, buffer_size))

# See tests for a more interesting demo.
```

# TODO
- [ ] Write ExAlsa module documentation
- [ ] Explore necessity of running on BEAM's dirty scheduler and implication of doing so 
- [ ] Write ALSA configuration documentation (may live in a different repository)
  - [ ] Brief overview of sampling, waves, PMC. Readers should walk away confident that they can produce sound by writing numbers in a vector. 
  - [ ] How to calculate the maximum sleep between writes
  - [ ] A better description of each relevant ALSA config -- difference between SW params and HW params
  - [ ] What are periods/frames/buffers
  - [ ] Maybe some overview of Linux sound stack
- [ ] Finish writing configuration API
- [ ] Support different access methods
- [ ] Support different formats
- [ ] Capture sound

## Influences/Alternative packages
Check out Mikael Karlsson's excellent https://github.com/karlsson/xalsa for an Erlang/Elixir solution using OTP.

## Further ALSA Reading
A lot of the documentation here is referenced from the URLs below:

* https://www.linuxjournal.com/article/6735
* https://alsa.opensrc.org/
* https://www.alsa-project.org/wiki/Tutorials_and_Presentations
* https://www.alsa-project.org/wiki/FramesPeriods
* https://stackoverflow.com/questions/24040672/the-meaning-of-period-in-alsa
* https://albertlockett.wordpress.com/2013/11/06/creating-digital-audio-with-alsa/
* https://www.spinics.net/lists/alsa-devel/msg58343.html
