defmodule ArtemisNotify.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      supervisor(ArtemisNotify.IntervalSupervisor, [])
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: ArtemisNotify.Supervisor)
  end
end
