defmodule Artemis.EventTemplateTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.EventTemplate
  alias Artemis.Team

  @preload [:team]

  describe "associations - team" do
    setup do
      event_template = insert(:event_template)

      {:ok, event_template: Repo.preload(event_template, @preload)}
    end

    test "deleting association removes record", %{event_template: event_template} do
      assert Repo.get(Team, event_template.team.id) != nil

      Repo.delete!(event_template.team)

      assert Repo.get(Team, event_template.team.id) == nil
      assert Repo.get(EventTemplate, event_template.id) == nil
    end

    test "deleting record does not remove association", %{event_template: event_template} do
      assert Repo.get(Team, event_template.team.id) != nil

      Repo.delete!(event_template)

      assert Repo.get(Team, event_template.team.id) != nil
      assert Repo.get(EventTemplate, event_template.id) == nil
    end
  end
end
