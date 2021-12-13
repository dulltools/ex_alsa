defmodule ExAlsa do
  @moduledoc """
  Documentation for `ExAlsa`.
  """

  @type rates() :: 44100 | 48000 | 96000 | 192_000

  @on_load :load_nifs
  def load_nifs do
    :ok = :code.priv_dir(:ex_alsa)
    |> Path.join("ex_alsa")
    |> :erlang.load_nif(0)
  end

  @spec open_handle(String.t()) :: any() 
  def open_handle(device) do
    _open_handle(String.to_charlist(device))
  end


  @spec set_params(any(), pos_integer(), rates(), pos_integer(), pos_integer()) :: any() 
  def set_params(handle, channels, rate, period_size, buffer_period_size_ratio) do
    _set_params(
      handle,
      channels, 
      rate,
      period_size,
      buffer_period_size_ratio, 0)
  end

  @spec _open_handle(charlist()) :: any() 
  def _open_handle(_device) do
    :erlang.nif_error(:not_loaded)
  end

  @spec _set_params(any(), integer(), integer(), integer(), integer(), integer()) :: any() 
  def _set_params(_handle, _channels, _rate, _period_size, _buffer_period_size_ratio, _stop_threshold) do
    :erlang.nif_error(:not_loaded)
  end

  @spec write(any(), charlist()) :: any() 
  def write(_handle, _frames) do
    :erlang.nif_error(:not_loaded)
  end
end
