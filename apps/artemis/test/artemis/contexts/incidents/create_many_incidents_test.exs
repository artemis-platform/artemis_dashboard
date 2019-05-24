defmodule Artemis.CreateManyIncidentsTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.CreateManyIncidents
  alias Artemis.Incident
  alias Artemis.Repo

  describe "call!" do
    test "returns error when params are empty" do
      assert_raise Artemis.Context.Error, fn () ->
        CreateManyIncidents.call!(%{}, Mock.system_user())
      end
    end

    test "creates an incident when passed valid params" do
      params = params_for(:incident)

      result = CreateManyIncidents.call!(params, Mock.system_user())

      assert Repo.get_by(Incident, source_uid: params.source_uid) != nil
      assert result.total == 1
    end

    test "creates an incidents when passed valid params" do
      params1 = params_for(:incident)
      params2 = params_for(:incident)

      result = CreateManyIncidents.call!([params1, params2], Mock.system_user())

      assert Repo.get_by(Incident, source_uid: params1.source_uid) != nil
      assert Repo.get_by(Incident, source_uid: params2.source_uid) != nil
      assert result.total == 2
    end
  end

  describe "call" do
    test "returns error when params are empty" do
      {:error, _} = CreateManyIncidents.call([], Mock.system_user())
    end

    test "creates an incident when passed valid params" do
      params = params_for(:incident)

      {:ok, result} = CreateManyIncidents.call(params, Mock.system_user())

      assert Repo.get_by(Incident, source_uid: params.source_uid) != nil
      assert result.total == 1
    end

    test "creates an incidents when passed valid params" do
      params1 = params_for(:incident)
      params2 = params_for(:incident)

      {:ok, result} = CreateManyIncidents.call([params1, params2], Mock.system_user())

      assert Repo.get_by(Incident, source_uid: params1.source_uid) != nil
      assert Repo.get_by(Incident, source_uid: params2.source_uid) != nil
      assert result.total == 2
    end

    test "filters incidents with omitted required values" do
      valid_params1 = params_for(:incident)
      valid_params2 = params_for(:incident)
      invalid_params1 = params_for(:incident, source: nil)
      invalid_params2 = params_for(:incident, status: "invalid status")

      params = [
        invalid_params1,
        invalid_params2,
        valid_params1,
        valid_params2,
        "",
        nil,
        %{}
      ]

      count_before = Incident
        |> select([i], count(i.id))
        |> Repo.one

      {:ok, result} = CreateManyIncidents.call(params, Mock.system_user())

      count_after = Incident
        |> select([i], count(i.id))
        |> Repo.one

      assert Repo.get_by(Incident, source_uid: valid_params1.source_uid) != nil
      assert Repo.get_by(Incident, source_uid: valid_params2.source_uid) != nil

      assert Repo.get_by(Incident, source_uid: invalid_params1.source_uid) == nil
      assert Repo.get_by(Incident, source_uid: invalid_params2.source_uid) == nil

      assert count_after == count_before + result.total
      assert result.total == 2
    end

    test "also updates existing records" do
      existing1 = insert(:incident, status: "acknowledged")
      existing2 = insert(:incident)

      existing_params1 = existing1
        |> Map.from_struct()
        |> Map.put(:status, "resolved")
        |> Map.put(:title, "Updated Title")
      existing_params2 = Map.from_struct(existing2)
      valid_params1 = params_for(:incident)
      valid_params2 = params_for(:incident)
      invalid_params1 = params_for(:incident, source: nil)
      invalid_params2 = params_for(:incident, status: "invalid status")

      params = [
        existing_params1,
        invalid_params2,
        valid_params1,
        invalid_params1,
        "",
        nil,
        valid_params2,
        existing_params2,
        %{}
      ]

      {:ok, result} = CreateManyIncidents.call(params, Mock.system_user())

      count_after = Incident
        |> select([i], count(i.id))
        |> Repo.one

      # Existing records are changed if passed different params

      updated_existing1 = Repo.get_by(Incident, source_uid: existing1.source_uid)

      assert updated_existing1.status == existing_params1.status
      assert updated_existing1.title == existing_params1.title
      assert updated_existing1.triggered_by == existing1.triggered_by

      # Existing records are untouched if passed as params

      updated_existing2 = Repo.get_by(Incident, source_uid: existing2.source_uid)

      assert updated_existing2.status == existing2.status
      assert updated_existing2.title == existing2.title
      assert updated_existing2.triggered_by == existing2.triggered_by

      # Records are created for each new set of valid params

      assert Repo.get_by(Incident, source_uid: valid_params1.source_uid) != nil
      assert Repo.get_by(Incident, source_uid: valid_params2.source_uid) != nil

      # Invalid params are ignored

      assert Repo.get_by(Incident, source_uid: invalid_params1.source_uid) == nil
      assert Repo.get_by(Incident, source_uid: invalid_params2.source_uid) == nil

      # Results count includes created and updated

      assert count_after == result.total
      assert result.total == 4
    end
  end

  describe "broadcasts" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      {:ok, result} = CreateManyIncidents.call(params_for(:incident), Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "incidents:created:many",
        payload: %{
          data: ^result
        }
      }
    end
  end
end
