defmodule ExAlsa do
  @moduledoc """
  A NIF-backed library for interfacing with ALSA.
  """

  @typedoc "Sample rates allowed"
  @type rates() :: 44100 | 48000 | 96000 | 192_000

  @type options :: %{
    channels: pos_integer(),
    rate: rates(),
    period_size: pos_integer(),
    buffer_size: pos_integer(),
    periods: pos_integer(),
    start_threshold: pos_integer()
  }

  @type handle :: any()

  @doc false
  @on_load :load_nifs
  def load_nifs do
    :ok =
      :code.priv_dir(:ex_alsa)
      |> Path.join("ex_alsa")
      |> :erlang.load_nif(0)
  end

  @doc """
  Creates a handler which opens an audio interface to the sound card and device.
  """
  @spec open_handle(String.t()) :: handle()
  def open_handle(device) do
    _open_handle(String.to_charlist(device))
  end

  @doc """
  Pass parameters and attempt to set them in ALSA. Will set both HW params and
  SW params.

  ## Options
  Depending on what you set here, it will change the structure of the payload
  you `write/2`. So pay attention.

  * `channels` - a representation of sound coming from or going to a single point
  e.g. A single microphone can produce one channel of audio and a single 
  speaker can receive one channel of audio. Headphones would receive 2 channels of sound. [Wildlife Acoustics](https://www.wildlifeacoustics.com/resources/faqs/what-is-an-audio-channel)

  * `rate` - The number of samples that are inputted or outputted per second (Hz).

  * `period_size` - The number of [frames](TODO) inputted/outputted before the sound card
  checks for more.

  * `periods` - The number of periods in a buffer.

  * 
  ## How ALSA API works
  ALSA is both notoriously esoteric and famously helpful when it comes to
  configuring how you want ALSA and the sound driver to operate. ALSA offers
  an API that allows you to put what you would like, and it will then return
  to you what the soundcard can actually support. This is incredibly helpful,
  but note that it doesn't support this in all cases, and you have if you're
  doing any operations based on a defined buffer or period size, you have to
  make sure you use what ALSA returns unless you're certain your soundcard
  supports your configuration.

  """
  @spec set_params(handle(), options()) :: handle()
  def set_params(handle, options) do
    channels = Map.get(options, :channels, 1)
    rate = Map.fetch!(options, :rate)
    period_size = Map.get(options, :period_size)
    periods = Map.get(options, :periods, 2)
    buffer_size = Map.get(options, :buffer_size, periods * period_size)
    start_threshold = Map.get(options, :start_threshold, buffer_size * 2)

    _set_params(
      handle,
      channels,
      rate,
      period_size,
      periods,
      buffer_size,
      start_threshold
    )
  end

  @doc """
  Writes to the soundcard. ExAlsa NIF uses the synchronous `snd_pcm_writei`. 

  `write` will prevent overruns (when more frames are sent than what's available
  in the buffer), by dismissing them and returning the # of frames available in
  the buffer. It will not prevent underruns (sending too little frames).
  """
  @spec write(handle(), charlist()) :: {:error, integer()} | {:ok, integer(), integer()}
  def write(_handle, _frames) do
    :erlang.nif_error(:not_loaded)
  end

  @spec _open_handle(charlist()) :: handle()
  def _open_handle(_device) do
    :erlang.nif_error(:not_loaded)
  end

  @spec _set_params(
    handle(),
    pos_integer(),
    rates(),
    pos_integer(),
    pos_integer(),
    pos_integer(),
    pos_integer()
  ) :: handle()
  def _set_params(
    _handle,
    _channels,
    _rate,
    _period_size,
    _periods,
    _buffer_size,
    _start_threshold
  ) do
    :erlang.nif_error(:not_loaded)
  end
end
