defmodule Artemis.DataCenterTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  describe "attributes - constraints" do
    test "slug must be unique" do
      existing = insert(:data_center)

      assert_raise Ecto.ConstraintError, fn ->
        insert(:data_center, slug: existing.slug)
      end
    end
  end
end
