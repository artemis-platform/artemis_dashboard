{:ok, _} = Application.ensure_all_started(:hound)

configuration = ExUnit.configuration()
excludes = Keyword.fetch!(configuration, :exclude)

unless Enum.member?(excludes, :cloudant_setup) do
  IO.inspect("Starting Cloudant Database Setup")
  Artemis.Drivers.IBMCloudant.DeleteAll.call()
  Artemis.Drivers.IBMCloudant.CreateAll.call()
  IO.inspect("Completed Cloudant Database Setup")
end

ExUnit.configure(exclude: [cloudant_exclusive_feature: true, pending: true])
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Artemis.Repo, :manual)
Ecto.Adapters.SQL.Sandbox.mode(ArtemisLog.Repo, :manual)
