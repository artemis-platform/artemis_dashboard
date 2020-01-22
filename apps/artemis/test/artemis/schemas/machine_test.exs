defmodule Artemis.MachineTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  describe "attributes - constraints" do
    test "slug must be unique" do
      existing = insert(:machine)

      assert_raise Ecto.ConstraintError, fn ->
        insert(:machine, slug: existing.slug)
      end
    end
  end
end
