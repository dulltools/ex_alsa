defmodule ExAlsa do
  @moduledoc """
  A NIF-backed module for interfacing with ALSA. This is a dirty NIF, meaning that it operates on the BEAM I/O scheduler and that there's no guarantee it will return within ~1-2ms. In fact, depending on how you configure the library, it could take multiple seconds to return. This onus is entirely on the operator to manager. The goal of this library is to act as a pass-through to ALSA, while attemping to improve the configuration experience.
  """

  @typedoc "Sample rates allowed"
  @type rates() :: 44100 | 48000 | 96000 | 192_000

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
  @spec open_handle(String.t()) :: any()
  def open_handle(device) do
    _open_handle(String.to_charlist(device))
  end

  @doc """
  TODO
  """
  @spec set_params(any(), pos_integer(), rates(), pos_integer(), pos_integer()) :: any()
  def set_params(handle, channels, rate, period_size, buffer_period_size_ratio) do
    _set_params(
      handle,
      channels,
      rate,
      period_size,
      buffer_period_size_ratio,
      0
    )
  end

  @doc """
  Writes to the soundcard. ExAlsa NIF uses the synchronous `snd_pcm_writei`. 

  `write` will prevent overruns (when more frames are sent than what's available in the buffer), by dismissing them and returning the # of frames available in the buffer. It will not prevent underruns (sending too little frames).
  """
  @spec write(any(), charlist()) :: {:error, integer()} | {:ok, integer(), integer()}
  def write(_handle, _frames) do
    :erlang.nif_error(:not_loaded)
  end

  @spec _open_handle(charlist()) :: any()
  def _open_handle(_device) do
    :erlang.nif_error(:not_loaded)
  end

  @spec _set_params(any(), integer(), integer(), integer(), integer(), integer()) :: any()
  def _set_params(
        _handle,
        _channels,
        _rate,
        _period_size,
        _buffer_period_size_ratio,
        _stop_threshold
      ) do
    :erlang.nif_error(:not_loaded)
  end
end
