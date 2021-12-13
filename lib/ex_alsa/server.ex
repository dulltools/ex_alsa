defmodule ExAlsa.Server do
  use GenStage
  def start_link(opts) do
    GenStage.start_link(__MODULE__, opts)
  end

  @impl true
  def init(_) do #device \\ "default", _params \\ []) do
    {:ok, handle} = ExAlsa.open_handle("default")
    {:ok, _} = ExAlsa.set_params(handle, 1,2,3,4)
    {:consumer, %{
      handle: handle,
      producer: []
    }, subscribe_to: [ExAlsa.Producer]}
  end
  
  def handle_subscribe(:producer, opts, from, %{producer: producer} = state) do
    # Register the producer in the state
    #unless is_nil(producer) do
    #  {:stop, "Producer already set", state}
    #else
      state = Map.update(state, :producer, [], &([&1 | producer]))
      ask_and_schedule(from)
      {:manual, state}
    #end
  end

  
  def handle_info({:ask, from}, state) do
    ask_and_schedule(from)
    {:noreply, [], state}
  end

  defp ask_and_schedule(from) do
    case from do
      nil ->
        nil
      from ->
        # 2205 = 44100/1000ms = x/50ms
        GenStage.ask(from, 705)
        Process.send_after(self(), {:ask, from}, 30)
    end
  end

  defp send_frames(handle, from, frames, num) do
    :erlang.monotonic_time(:milli_seconds) |> IO.inspect
    case ExAlsa.write(handle, Enum.take(frames, num)) do
      {:error, requested} -> 
        requested
        #send_frames(handle, from, frames, requested)
      {:ok, sent, requested} -> 
        #if requested > 3000 do
        #  GenStage.ask(from, 2205)
        #end

        requested
    end
  end

  def handle_events(frames, from, %{handle: handle} = state) do
    requested = send_frames(handle, from, frames, Enum.count(frames))
    # TODO I may want to make this a consumer producer event and emit events here -- probably not though...
    {:noreply, [], state}
  end

  def handle_cancel(_, from, state) do
    # Remove the producers from the map on unsubscribe
    {:noreply, [], Map.put(state, :producer, nil)}
  end
end
