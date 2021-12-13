defmodule ExAlsa.Producer do
  use GenStage

  def start_link(initial \\ 0) do
    GenStage.start_link(__MODULE__, initial, name: __MODULE__)
  end

  def init(counter) do
    {:producer, counter, buffer_size: :infinity}
  end

  def handle_demand(demand, state) do
    radians_per_second = 240 * 2.0 * :math.pi;
    seconds_per_frame = 1.0/44100.0
    state = rem(state, 44100)
    events = Enum.map(0..(state + demand - 1), fn i -> :math.sin(radians_per_second * i * seconds_per_frame) end)

    {:noreply, events, state + demand}
  end
end
