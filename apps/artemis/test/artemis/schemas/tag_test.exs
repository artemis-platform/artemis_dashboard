defmodule Artemis.TagTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  alias Artemis.Tag

  describe "attributes - constraints" do
    test "compound type and slug must be unique" do
      existing = insert(:tag)

      assert_raise Ecto.ConstraintError, fn () ->
        insert(:tag, type: existing.type, slug: existing.slug)
      end

      %Tag{} = insert(:tag, type: "other-type", slug: existing.slug)
    end

    test "compound type and name must be unique" do
      existing = insert(:tag)

      assert_raise Ecto.ConstraintError, fn () ->
        insert(:tag, type: existing.type, name: existing.name)
      end

      %Tag{} = insert(:tag, type: "other-type", name: existing.name)
    end
  end
end
