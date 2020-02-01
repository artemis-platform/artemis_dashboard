defmodule Artemis.SystemTaskTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Artemis.Factories

  alias Artemis.SystemTask

  describe "changeset - validations" do
    test "extra_params" do
      struct = struct(Artemis.SystemTask)

      # With valid value

      params = params_for(:system_task)

      changeset = SystemTask.changeset(struct, params)

      assert changeset.valid?

      # With invalid value

      params = params_for(:system_task, extra_params: [invalid: "data"])

      changeset = SystemTask.changeset(struct, params)

      refute changeset.valid?
      assert errors_on(changeset) == %{extra_params: ["is invalid"]}

      # With empty value

      params = params_for(:system_task, extra_params: nil)

      changeset = SystemTask.changeset(struct, params)

      assert changeset.valid?
    end

    test "type" do
      struct = struct(Artemis.SystemTask)

      # With valid value

      params = params_for(:system_task)

      changeset = SystemTask.changeset(struct, params)

      assert changeset.valid?

      # With invalid value

      params = params_for(:system_task, type: "INVALID")

      changeset = SystemTask.changeset(struct, params)

      refute changeset.valid?
      assert errors_on(changeset) == %{type: ["invalid type"]}

      # With empty value

      params = params_for(:system_task, type: nil)

      changeset = SystemTask.changeset(struct, params)

      refute changeset.valid?
      assert errors_on(changeset) == %{type: ["can't be blank"]}
    end
  end
end
