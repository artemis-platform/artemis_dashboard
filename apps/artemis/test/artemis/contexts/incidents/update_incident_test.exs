defmodule Artemis.UpdateIncidentTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.Incident
  alias Artemis.UpdateIncident

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50000000
      params = params_for(:incident)

      assert_raise Artemis.Context.Error, fn () ->
        UpdateIncident.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      incident = insert(:incident)
      params = %{}

      updated = UpdateIncident.call!(incident, params, Mock.system_user())

      assert updated.title == incident.title
    end

    test "updates a record when passed valid params" do
      incident = insert(:incident)
      params = params_for(:incident)

      updated = UpdateIncident.call!(incident, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      incident = insert(:incident)
      params = params_for(:incident)

      updated = UpdateIncident.call!(incident.id, params, Mock.system_user())

      assert updated.title == params.title
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50000000
      params = params_for(:incident)

      {:error, _} = UpdateIncident.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      incident = insert(:incident)
      params = %{}

      {:ok, updated} = UpdateIncident.call(incident, params, Mock.system_user())

      assert updated.title == incident.title
    end

    test "updates a record when passed valid params" do
      incident = insert(:incident)
      params = params_for(:incident)

      {:ok, updated} = UpdateIncident.call(incident, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      incident = insert(:incident)
      params = params_for(:incident)

      {:ok, updated} = UpdateIncident.call(incident.id, params, Mock.system_user())

      assert updated.title == params.title
    end
  end

  describe "associations - tags" do
    test "updates tags" do
      incident = :incident
        |> insert()
        |> Repo.preload([:tags])

      assert incident.tags == []

      tag1 = insert(:tag)
      tag2 = params_for(:tag)
      params = incident
        |> Map.from_struct
        |> Map.put(:tags, [%{id: tag1.id}, tag2])

      {:ok, incident} = UpdateIncident.call(incident, params, Mock.system_user())

      incident = Incident
        |> preload([:tags])
        |> Repo.get(incident.id)

      assert length(incident.tags) == 2

      assert hd(incident.tags).name == tag1.name
      assert hd(incident.tags).slug == tag1.slug
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      incident = insert(:incident)
      params = params_for(:incident)

      {:ok, updated} = UpdateIncident.call(incident, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "incident:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end

