defmodule ExAlsa.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {ExAlsa.Producer, 0},
      {ExAlsa.Server, []}
    ]
    opts = [strategy: :one_for_one, name: ExAlsa.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
