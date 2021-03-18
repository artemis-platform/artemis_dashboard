defmodule Artemis.Worker.KeyValueCleaner do
  use Artemis.IntervalWorker,
    enabled: enabled?(),
    delayed_start: :timer.seconds(15),
    interval: :timer.seconds(15),
    name: :key_value_cleaner

  alias Artemis.GetSystemUser
  alias Artemis.DeleteAllKeyValues

  # Callbacks

  @impl true
  def call(_data, _config) do
    user = GetSystemUser.call!()
    date = Timex.now()

    params = %{
      filters: %{
        expire_at_lte: date
      }
    }

    DeleteAllKeyValues.call(params, user)
  end

  # Helpers

  defp enabled?() do
    Artemis.Helpers.AppConfig.all_enabled?([
      [:artemis, :umbrella, :background_workers],
      [:artemis, :actions, :key_value_cleaner]
    ])
  end
end
