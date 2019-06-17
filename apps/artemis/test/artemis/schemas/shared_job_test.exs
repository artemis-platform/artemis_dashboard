defmodule Artemis.SharedJobTest do
  use Artemis.DataCase
  use ExUnit.Case, async: true

  import Artemis.Factories

  alias Artemis.SharedJob

  describe "changeset - validations" do
    test "validates `raw_data` is can be encoded to JSON" do
      struct = 
        :shared_job
        |> params_for()
        |> SharedJob.from_json()

      # Other Params

      other_params = %{
        name: "new name"
      }

      changeset = SharedJob.changeset(struct, other_params)

      assert changeset.valid? == true

      # Valid `raw_data` Params

      valid_params = %{
        raw_data: %{
          "valid" => "data"
        }
      }

      changeset = SharedJob.changeset(struct, valid_params)

      assert changeset.valid? == true

      # Invalid `raw_data` Params

      invalid_params = %{
        raw_data: %{
          "valid" => [one: "one", one: "two"]
        }
      }

      changeset = SharedJob.changeset(struct, invalid_params)

      assert changeset.valid? == false
      assert errors_on(changeset) == %{raw_data: ["invalid json"]}
    end
  end

  describe "helpers - from_json" do
    test "returns a struct from encoded JSON" do
      params = 
        :shared_job
        |> params_for()
        |> Jason.encode!()

      struct = SharedJob.from_json(params)

      assert struct._id != nil
      assert struct._id == Jason.decode!(params)["_id"]
    end

    test "returns a struct from decoded JSON" do
      params = 
        :shared_job
        |> params_for()
        |> Jason.encode!()
        |> Jason.decode!()

      struct = SharedJob.from_json(params)

      assert struct._id != nil
      assert struct._id == params["_id"]
    end

    test "drops keys not defined in schema; stores original data under `raw_data`" do
      params = 
        :shared_job
        |> params_for()
        |> Jason.encode!()
        |> Jason.decode!()
        |> Map.put("custom_key", "custom_value")

      struct = SharedJob.from_json(params)

      assert struct._id == params["_id"]

      assert Map.get(struct, :custom_key) == nil
      assert Map.get(struct, "custom_key") == nil

      assert struct.raw_data["custom_key"] == params["custom_key"]
    end
  end

  describe "helpers - to_json" do
    test "uses `raw_data` to ensure all keys are preserved" do
      params = 
        :shared_job
        |> params_for()
        |> Jason.encode!()
        |> Jason.decode!()
        |> Map.put("custom_key", "custom_value")

      struct = SharedJob.from_json(params)

      assert Map.get(struct, :custom_key) == nil
      assert Map.get(struct, "custom_key") == nil

      json = SharedJob.to_json(struct)

      assert Map.has_key?(json, "raw_data") == false
      assert json["custom_key"] == "custom_value"
    end
  end
end
