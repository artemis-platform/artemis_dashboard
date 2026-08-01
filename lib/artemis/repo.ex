defmodule Artemis.Repo do
  use Ecto.Repo,
    otp_app: :artemis,
    adapter: Ecto.Adapters.SQLite3
end
