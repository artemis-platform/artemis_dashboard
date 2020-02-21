defmodule Artemis.GetEventTemplateTest do
  use Artemis.DataCase

  import Artemis.Factories

  alias Artemis.GetEventTemplate

  setup do
    event_template = insert(:event_template)

    {:ok, event_template: event_template}
  end

  describe "call" do
    test "returns nil event_template not found" do
      invalid_id = 50_000_000

      assert GetEventTemplate.call(invalid_id, Mock.system_user()) == nil
    end

    test "finds event_template by id", %{event_template: event_template} do
      assert GetEventTemplate.call(event_template.id, Mock.system_user()).id == event_template.id
    end

    test "finds record by keyword list", %{event_template: event_template} do
      assert GetEventTemplate.call([title: event_template.title], Mock.system_user()).id == event_template.id
    end
  end

  describe "call!" do
    test "raises an exception event_template not found" do
      invalid_id = 50_000_000

      assert_raise Ecto.NoResultsError, fn ->
        GetEventTemplate.call!(invalid_id, Mock.system_user()) == nil
      end
    end

    test "finds event_template by id", %{event_template: event_template} do
      assert GetEventTemplate.call!(event_template.id, Mock.system_user()).id == event_template.id
    end
  end
end
