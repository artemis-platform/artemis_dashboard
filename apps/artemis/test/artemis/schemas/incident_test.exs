defmodule Artemis.IncidentTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Comment
  alias Artemis.Incident
  alias Artemis.Repo
  alias Artemis.Tag

  @preload [:comments, :tags]

  describe "attributes - constraints" do
    test "compound source uid value must be unique" do
      # Raise Exception when both columns match

      _existing = insert(:incident, source: "test", source_uid: "1")
      params = params_for(:incident, source: "test", source_uid: "1")

      assert_raise Ecto.ConstraintError, fn () ->
        %Incident{}
        |> Incident.changeset(params)
        |> Repo.insert()
      end

      # Ignores Nulls

      _existing = insert(:incident, source: "test", source_uid: nil)
      params = params_for(:incident, source: "test", source_uid: nil)

      {:ok, _} = %Incident{}
        |> Incident.changeset(params)
        |> Repo.insert()

      # Uniqueness determined by both columns

      _existing = insert(:incident, source: "test", source_uid: "2")
      params = params_for(:incident, source: "different-source", source_uid: "2")

      {:ok, _} = %Incident{}
        |> Incident.changeset(params)
        |> Repo.insert()
    end
  end

  describe "associations - comments" do
    setup do
      comments = insert_list(3, :comment)
      incident = insert(:incident, comments: comments)

      {:ok, comments: comments, incident: Repo.preload(incident, @preload)}
    end

    test "updating association does not change record", %{incident: incident} do
      assert length(incident.comments) == 3

      comment = Repo.get(Comment, hd(incident.comments).id)

      assert comment != nil
      assert comment.title != "Updated Title"

      params = %{title: "Updated Title"}

      {:ok, comment} = comment
        |> Comment.changeset(params)
        |> Repo.update()

      assert comment != nil
      assert comment.title == "Updated Title"

      incident = Incident
        |> preload(^@preload)
        |> Repo.get(incident.id)

      assert length(incident.comments) == 3
    end

    test "deleting association does not change record", %{incident: incident} do
      assert length(incident.comments) == 3

      comment = Repo.get(Comment, hd(incident.comments).id)

      Repo.delete!(comment)

      incident = Incident
        |> preload(^@preload)
        |> Repo.get(incident.id)

      assert length(incident.comments) == 2
    end

    test "deleting record only removes the join table, not the associated records", %{incident: incident} do
      # Only the join table records are removed. This is a limitation of Ecto many_to_many:
      # https://hexdocs.pm/ecto/Ecto.Schema.html#many_to_many/3-removing-data
      #
      comment = Comment
        |> preload([:incidents])
        |> Repo.get(hd(incident.comments).id)

      assert !is_nil(comment)
      assert length(comment.incidents) == 1

      Repo.delete!(incident)

      comment = Comment
        |> preload([:incidents])
        |> Repo.get(hd(incident.comments).id)

      assert !is_nil(comment)
      assert length(comment.incidents) == 0
    end
  end

  describe "associations - tags" do
    setup do
      tags = insert_list(3, :tag)
      incident = insert(:incident, tags: tags)

      {:ok, tags: tags, incident: Repo.preload(incident, @preload)}
    end

    test "updating association does not change record", %{incident: incident} do
      assert length(incident.tags) == 3

      tag = Repo.get(Tag, hd(incident.tags).id)

      assert tag != nil
      assert tag.name != "Updated Name"

      params = %{name: "Updated Name"}

      {:ok, tag} = tag
        |> Tag.changeset(params)
        |> Repo.update()

      assert tag != nil
      assert tag.name == "Updated Name"

      incident = Incident
        |> preload(^@preload)
        |> Repo.get(incident.id)

      assert length(incident.tags) == 3
    end

    test "deleting association does not change record", %{incident: incident} do
      assert length(incident.tags) == 3

      tag = Repo.get(Tag, hd(incident.tags).id)

      Repo.delete!(tag)

      incident = Incident
        |> preload(^@preload)
        |> Repo.get(incident.id)

      assert length(incident.tags) == 2
    end

    test "deleting record only removes the join table, not the associated records", %{incident: incident} do
      # Only the join table records are removed. This is a limitation of Ecto many_to_many:
      # https://hexdocs.pm/ecto/Ecto.Schema.html#many_to_many/3-removing-data
      #
      tag = Tag
        |> preload([:incidents])
        |> Repo.get(hd(incident.tags).id)

      assert !is_nil(tag)
      assert length(tag.incidents) == 1

      Repo.delete!(incident)

      tag = Tag
        |> preload([:incidents])
        |> Repo.get(hd(incident.tags).id)

      assert !is_nil(tag)
      assert length(tag.incidents) == 0
    end
  end
end
