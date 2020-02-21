defmodule Artemis.UpdateEventTemplateTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.UpdateEventTemplate

  describe "call!" do
    test "raises an exception when id not found" do
      invalid_id = 50_000_000
      params = params_for(:event_template)

      assert_raise Artemis.Context.Error, fn ->
        UpdateEventTemplate.call!(invalid_id, params, Mock.system_user())
      end
    end

    test "returns successfully when params are empty" do
      event_template = insert(:event_template)
      params = %{}

      updated = UpdateEventTemplate.call!(event_template, params, Mock.system_user())

      assert updated.title == event_template.title
    end

    test "updates a record when passed valid params" do
      event_template = insert(:event_template)
      params = params_for(:event_template)

      updated = UpdateEventTemplate.call!(event_template, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      event_template = insert(:event_template)
      params = params_for(:event_template)

      updated = UpdateEventTemplate.call!(event_template.id, params, Mock.system_user())

      assert updated.title == params.title
    end
  end

  describe "call" do
    test "returns an error when id not found" do
      invalid_id = 50_000_000
      params = params_for(:event_template)

      {:error, _} = UpdateEventTemplate.call(invalid_id, params, Mock.system_user())
    end

    test "returns successfully when params are empty" do
      event_template = insert(:event_template)
      params = %{}

      {:ok, updated} = UpdateEventTemplate.call(event_template, params, Mock.system_user())

      assert updated.title == event_template.title
    end

    test "updates a record when passed valid params" do
      event_template = insert(:event_template)
      params = params_for(:event_template)

      {:ok, updated} = UpdateEventTemplate.call(event_template, params, Mock.system_user())

      assert updated.title == params.title
    end

    test "updates a record when passed an id and valid params" do
      event_template = insert(:event_template)
      params = params_for(:event_template)

      {:ok, updated} = UpdateEventTemplate.call(event_template.id, params, Mock.system_user())

      assert updated.title == params.title
    end
  end

  describe "broadcast" do
    test "publishes event and record" do
      ArtemisPubSub.subscribe(Artemis.Event.get_broadcast_topic())

      event_template = insert(:event_template)
      params = params_for(:event_template)

      {:ok, updated} = UpdateEventTemplate.call(event_template, params, Mock.system_user())

      assert_received %Phoenix.Socket.Broadcast{
        event: "event_template:updated",
        payload: %{
          data: ^updated
        }
      }
    end
  end
end
