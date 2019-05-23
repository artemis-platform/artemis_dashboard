defmodule Artemis.GetIncidentTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetIncident

  setup do
    incident = insert(:incident)

    {:ok, incident: incident}
  end

  describe "call" do
    test "returns nil incident not found" do
      invalid_id = 50000000

      assert GetIncident.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds incident by id", %{incident: incident} do
      assert GetIncident.call(incident.id, Mock.system_user()).id == incident.id
    end

    test "finds user keyword list", %{incident: incident} do
      assert GetIncident.call([source_uid: incident.source_uid, title: incident.title], Mock.system_user()).id == incident.id
    end
  end

  describe "call!" do
    test "raises an exception incident not found" do
      invalid_id = 50000000

      assert_raise Ecto.NoResultsError, fn () ->
        GetIncident.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds incident by id", %{incident: incident} do
      assert GetIncident.call!(incident.id, Mock.system_user()).id == incident.id
    end
  end
end
