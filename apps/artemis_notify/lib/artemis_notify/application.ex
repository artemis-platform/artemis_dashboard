defmodule ArtemisNotify.Application do
  @moduledoc """
  """
  def start(_type, _args) do
    children = []

    opts = [strategy: :one_for_one, name: ArtemisNotify.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
