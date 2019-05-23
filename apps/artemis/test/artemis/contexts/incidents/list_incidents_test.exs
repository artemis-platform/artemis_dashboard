defmodule Artemis.ListIncidentsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.ListIncidents
  alias Artemis.Repo
  alias Artemis.Incident

  setup do
    Repo.delete_all(Incident)

    {:ok, []}
  end

  describe "call" do
    test "returns empty list when no incidents exist" do
      assert ListIncidents.call(Mock.system_user()) == []
    end

    test "returns existing incident" do
      incident = insert(:incident)

      results = ListIncidents.call(Mock.system_user())

      assert hd(results).id  == incident.id
    end

    test "returns a list of incidents" do
      count = 3
      insert_list(count, :incident)

      incidents = ListIncidents.call(Mock.system_user())

      assert length(incidents) == count
    end
  end

  describe "call - params" do
    setup do
      incident = insert(:incident)

      {:ok, incident: incident}
    end

    test "filters" do
      insert_list(3, :incident)
      insert_list(2, :incident, source: "custom-source")

      params = %{}
      results = ListIncidents.call(params, Mock.system_user())

      assert length(results) > 2

      params = %{
        filters: %{
          source: "custom-source"
        }
      }
      results = ListIncidents.call(params, Mock.system_user())

      assert length(results) == 2
    end

    test "order" do
      insert_list(3, :incident)

      params = %{order: "title"}
      ascending = ListIncidents.call(params, Mock.system_user())

      params = %{order: "-title"}
      descending = ListIncidents.call(params, Mock.system_user())

      assert ascending == Enum.reverse(descending)
    end

    test "paginate" do
      params = %{
        paginate: true
      }

      response_keys = ListIncidents.call(params, Mock.system_user())
        |> Map.from_struct()
        |> Map.keys()

      pagination_keys = [
        :entries,
        :page_number,
        :page_size,
        :total_entries,
        :total_pages
      ]

      assert response_keys == pagination_keys
    end
  end
end
