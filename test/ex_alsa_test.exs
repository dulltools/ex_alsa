defmodule ExAlsaTest do
  use ExUnit.Case
  doctest ExAlsa

  describe "ExAlsa" do
    test "open_handle/1 returns handle for default device" do
      {:ok, _handle} = ExAlsa.open_handle("default")
    end

    test "open_handle/1 raises error when device does not exist" do
      assert_raise ArgumentError, fn ->
        ExAlsa.open_handle("device-does-not-exist")
      end
    end

    test "set_params/2 raises error when device does not exist" do
      {:ok, handle} = ExAlsa.open_handle("default")

      """
      options = %{
        sample_rate: 44100,
        channels: 1,
        buffer_time: 500000,
        period_time: 2,
        stop_threshold: 
      }
      {:ok, {sample_rate, channels, buffer_size, period_size, stop_threshold}} = ExAlsa.set_params(handle, 1, 44100, 512, 2) |> IO.inspect
      """
    end

    test "performance test" do
      {:ok, handle} = ExAlsa.open_handle("default")

      {:ok, {sample_rate, channels, buffer_size, period_size, stop_threshold}} =
        ExAlsa.set_params(handle, 1, 44100, 512, 2)

      seconds = 3

      frames = Enum.take(sin_freq(220, seconds), 44100 * seconds)
      seconds_per_frame = 1.0 / 44100.0
      frames = get_frames(seconds / 3)
      send_frame(frames, handle, 940)
    end
  end

  @doc """
  This is one implementation of a proper way to stream continuous playback. It's necessary
  to read the available buffer frames to know how many more frames to send. You cannot
  rely on sending a constant everytime without experiencing xruns (see documentation).
  Introduce a sleep which will decrease the calls to write but increase the number of
  frames sent. There is a natural maximum for this depending on your configuration 
  in order to avoid underruns. (see documentation for calculating this).
  """
  defp send_frame(frame, handle, n) do
    unless n == 0 do
      :timer.sleep(0)

      case ExAlsa.write(handle, Enum.take(frame, n)) do
        {:error, requested} ->
          # IO.puts("Error: #{requested}")
          send_frame(frame, handle, requested)

        {:ok, sent, requested} ->
          # IO.puts("Sent: #{sent} #{requested}")
          frame = Enum.drop(frame, sent)
          send_frame(frame, handle, min(Enum.count(frame), requested))
      end
    end
  end

  defp transform_freq(list) do
    Enum.reduce(list, 1, &(&1 * &2))
  end

  defp mix(list1, list2) do
    Enum.sum(list1) / Enum.count(list1)
  end

  defp get_frames(seconds) do
    pitch = 240.0

    freq = [
      [sin_freq(100, seconds), sin_freq(110, seconds), sin_freq(55, seconds)],
      [sin_freq(220, seconds), sin_freq(110, seconds), sin_freq(55, seconds)],
      [sin_freq(420, seconds), sin_freq(110, seconds), sin_freq(55, seconds)],
      [sin_freq(120, seconds), sin_freq(220, seconds), sin_freq(55, seconds)],
      [sin_freq(100, seconds), sin_freq(110, seconds), sin_freq(55, seconds)],
      [sin_freq(220, seconds), sin_freq(110, seconds), sin_freq(55, seconds)],
      [sin_freq(420, seconds), sin_freq(220, seconds), sin_freq(55, seconds)],
      [sin_freq(120, seconds), sin_freq(110, seconds), sin_freq(55, seconds)]
    ]

    freq
    |> Enum.flat_map(fn freqs -> Enum.zip_with(freqs, &transform_freq/1) end)
  end

  defp pause(time) do
    Enum.map(0..floor(44100 * time), fn _ -> 0 end)
  end

  defp sin_freq(pitch, time) do
    radians_per_second = pitch * 2.0 * :math.pi()
    seconds_per_frame = 1.0 / 44100.0

    Enum.map(0..floor(44100 * time), fn i ->
      :math.sin(radians_per_second * i * seconds_per_frame)
    end)
  end

  defp cos_freq(pitch, time) do
    radians_per_second = pitch * 2.0 * :math.pi()
    seconds_per_frame = 1.0 / 44100.0

    Enum.map(0..floor(44100 * time), fn i ->
      :math.cos(radians_per_second * i * seconds_per_frame)
    end)
  end
end
