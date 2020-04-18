defmodule Artemis.EventInstanceTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.EventInstance
  alias Artemis.EventTemplate

  @preload [:event_template]

  describe "attributes - constraints" do
    test "slug must be unique within associated event template" do
      existing = insert(:event_instance)

      # Duplicate slugs allowed for different associated event templates

      other_event_template = insert(:event_template)

      params = [
        event_template: other_event_template,
        slug: existing.slug
      ]

      %EventInstance{} = insert(:event_instance, params)

      # Duplicate slugs not allowed for same associated event template

      params = [
        event_template: existing.event_template,
        slug: existing.slug
      ]

      assert_raise Ecto.ConstraintError, fn ->
        insert(:event_instance, params)
      end
    end

    test "required associations" do
      params =
        :event_instance
        |> params_for()
        |> Map.delete(:event_template_id)

      {:error, changeset} =
        %EventInstance{}
        |> EventInstance.changeset(params)
        |> Repo.insert()

      assert errors_on(changeset) == %{event_template_id: ["can't be blank"]}
    end
  end

  describe "associations - event_template" do
    setup do
      event_instance = insert(:event_instance)

      {:ok, event_instance: Repo.preload(event_instance, @preload)}
    end

    test "deleting association removes record", %{event_instance: event_instance} do
      assert Repo.get(EventTemplate, event_instance.event_template.id) != nil

      Repo.delete!(event_instance.event_template)

      assert Repo.get(EventTemplate, event_instance.event_template.id) == nil
      assert Repo.get(EventInstance, event_instance.id) == nil
    end

    test "deleting record does not remove association", %{event_instance: event_instance} do
      assert Repo.get(EventTemplate, event_instance.event_template.id) != nil

      Repo.delete!(event_instance)

      assert Repo.get(EventTemplate, event_instance.event_template.id) != nil
      assert Repo.get(EventInstance, event_instance.id) == nil
    end
  end
end
