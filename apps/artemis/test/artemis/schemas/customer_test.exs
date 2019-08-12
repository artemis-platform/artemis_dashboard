defmodule Artemis.CustomerTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Ecto.Repo
  import Artemis.Factories

  describe "attributes - constraints" do
    test "name must be unique" do
      existing = insert(:customer)

      assert_raise Ecto.ConstraintError, fn ->
        insert(:customer, name: existing.name)
      end
    end
  end
end
