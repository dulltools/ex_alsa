defmodule ExAlsaTest do
  use ExUnit.Case
  doctest ExAlsa

   def measure(function) do
    function
    |> :timer.tc
    |> elem(0)
    |> Kernel./(1_000_000)
   end

  test "initial sound" do
    spec = {ExAlsa.Server, []}
    subscription_opts = [strategy: :one_for_one]
    specs = [{spec, subscription_opts}]
    Flow.into_specs(get_frames(), specs)
    :timer.sleep(10_000)
    #run()
  end

  def run() do
    {:ok, handle} = ExAlsa.open_handle("default")
    {:ok, {sample_rate, channels, buffer_size, period_size, stop_threshold}} = ExAlsa.set_params(handle, 1, 44100, 512, 2) |> IO.inspect


    frames = Enum.take(get_frames(), 44100 * 50)
    seconds_per_frame = 1.0/44100.0
    #spawn(fn -> {ok, frames_written} = ExAlsa.write(handle, List.first(frames)) |> IO.inspect end)
    
    send_frame(frames, handle, Enum.count(frames))
  end

  # Send 100 frames over
  # It consumes a bunch 50
  # Sends me back that only 10 is available
  # I need to skip 50 and hit 10
  def send_frame(frame, handle, n) do
    unless n == 0 do
      :timer.sleep(20)
      case ExAlsa.write(handle, Enum.take(frame, n)) do
        {:error, requested} -> send_frame(frame, handle, requested)
        {:ok, sent, requested} -> 
          frame = Enum.drop(frame, sent)
          send_frame(frame, handle, min(Enum.count(frame), requested))
      end
    end
  end

  defp transform_freq(list) do
    Enum.reduce(list, 1, &(&1*&2))
  end

  defp mix(list1, list2) do
    Enum.sum(list1) / Enum.count(list1)
  end


  defp get_frames() do
    pitch = 240.0
    time = 0.00

    freq = [
      [sin_freq(220, time), sin_freq(110, time), sin_freq(55, time)],
      [sin_freq(420, time), sin_freq(110, time), sin_freq(55, time)],
      [sin_freq(120, time), sin_freq(110, time), sin_freq(55, time)],
      [sin_freq(120, time), sin_freq(110, time), sin_freq(55, time)],
      [sin_freq(120, time), sin_freq(110, time), sin_freq(55, time)],
      [sin_freq(120, time), sin_freq(110, time), sin_freq(55, time)],
      [sin_freq(120, time), sin_freq(110, time), sin_freq(55, time)],
    ]

    Flow.from_enumerable(freq)
    |> Flow.flat_map(fn freqs -> Enum.zip_with(freqs, &transform_freq/1) end)
  end

  defp pause(time) do

    Enum.map(0..floor(44100*time), fn _-> 0 end)
  end

  defp sin_freq(pitch, time) do
    radians_per_second = pitch * 2.0 * :math.pi;
    seconds_per_frame = 1.0/44100.0
    Enum.map(0..floor(44100*time), fn i -> :math.sin(radians_per_second * i * seconds_per_frame) end)
  end

  defp cos_freq(pitch, time) do
    radians_per_second = pitch * 2.0 * :math.pi;
    seconds_per_frame = 1.0/44100.0
    Enum.map(0..floor(44100*time), fn i ->:math.cos(radians_per_second * i * seconds_per_frame) end)
  end

end
