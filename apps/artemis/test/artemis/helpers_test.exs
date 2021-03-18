defmodule Artemis.HelpersTest do
  use Artemis.DataCase, async: true

  describe "list_to_atoms" do
    test "converts a list of strings" do
      values = [
        "hello",
        "world",
        "Hello World"
      ]

      result = Artemis.Helpers.list_to_atoms(values)

      expected = [
        :hello,
        :world,
        :"Hello World"
      ]

      assert result == expected
    end

    test "keeps existing atoms" do
      values = [
        "hello",
        :world,
        "Hello World"
      ]

      result = Artemis.Helpers.list_to_atoms(values)

      expected = [
        :hello,
        :world,
        :"Hello World"
      ]

      assert result == expected
    end

    test "filters out values that aren't a bitstring or atom" do
      values = [
        "hello",
        :world,
        0,
        0.5,
        fn -> true end,
        %{hello: "world"},
        [hello: "world"],
        ["hello"]
      ]

      result = Artemis.Helpers.list_to_atoms(values)

      expected = [
        :hello,
        :world
      ]

      assert result == expected
    end

    test "can also convert a single value instead of a list" do
      result = Artemis.Helpers.list_to_atoms("Hello World")

      assert result == :"Hello World"
    end

    test ":allow option - removes any values not in the allow list" do
      allow = [
        :"Hello World"
      ]

      values = [
        "hello",
        :world,
        "Hello World"
      ]

      result = Artemis.Helpers.list_to_atoms(values, allow: allow)

      expected = [
        :"Hello World"
      ]

      assert result == expected
    end

    test ":allow option - single value conversions also support allow list" do
      allow = [
        :hello,
        :"Hello World"
      ]

      # Returns value when in list

      value = "hello"

      result = Artemis.Helpers.list_to_atoms(value, allow: allow)

      assert result == :hello

      # Returns nil when not in list

      value = "not in list"

      result = Artemis.Helpers.list_to_atoms(value, allow: allow)

      assert result == nil
    end
  end

  describe "deep_drop_by_value" do
    test "drops map entries with a matching value" do
      map = %{
        hello: "world"
      }

      result = Artemis.Helpers.deep_drop_by_value(map, "world")

      expected = %{}

      assert result == expected
    end

    test "drops entries on shallow maps" do
      map = %{
        hello: "world",
        other: "value"
      }

      result = Artemis.Helpers.deep_drop_by_value(map, "world")

      expected = %{
        other: "value"
      }

      assert result == expected
    end

    test "drops entries on nested maps" do
      map = %{
        hello: "world",
        nested: %{
          example: "value",
          hello: "hello",
          other: "world"
        }
      }

      result = Artemis.Helpers.deep_drop_by_value(map, "world")

      expected = %{
        nested: %{
          example: "value",
          hello: "hello"
        }
      }

      assert result == expected
    end

    test "accepts complex list values" do
      map = %{
        hello: ["world", "!"],
        level: "first",
        nested: %{
          hello: ["world", "!"],
          level: "second",
          nested: %{
            hello: ["world", "!"],
            level: "third"
          }
        }
      }

      match = ["world", "!"]

      result = Artemis.Helpers.deep_drop_by_value(map, match)

      expected = %{
        level: "first",
        nested: %{
          level: "second",
          nested: %{
            level: "third"
          }
        }
      }

      assert result == expected
    end

    test "accepts complex map values" do
      map = %{
        level: "first",
        nested: %{
          hello: "world"
        },
        next: %{
          level: "second",
          nested: %{
            hello: "world"
          }
        }
      }

      match = %{
        hello: "world"
      }

      result = Artemis.Helpers.deep_drop_by_value(map, match)

      expected = %{
        level: "first",
        next: %{
          level: "second"
        }
      }

      assert result == expected
    end
  end

  describe "indifferent_get" do
    test "updates bitstring keys when given a bitstring field name" do
      map = %{
        "hello" => "world"
      }

      field = "hello"

      result = Artemis.Helpers.indifferent_get(map, field)

      expected = "world"

      assert result == expected
    end

    test "updates bitstring keys when given an atom field name" do
      map = %{
        "hello" => "world"
      }

      field = :hello

      result = Artemis.Helpers.indifferent_get(map, field)

      expected = "world"

      assert result == expected
    end

    test "gets atom keys when given a bitstring field name" do
      map = %{
        hello: "world"
      }

      field = "hello"

      result = Artemis.Helpers.indifferent_get(map, field)

      expected = "world"

      assert result == expected
    end

    test "gets atom keys when given an atom field name" do
      map = %{
        hello: "world"
      }

      field = :hello

      result = Artemis.Helpers.indifferent_get(map, field)

      expected = "world"

      assert result == expected
    end

    test "returns nil when key is not found and fallback argument is not passed" do
      map = %{
        hello: "world"
      }

      field = "new key"

      result = Artemis.Helpers.indifferent_get(map, field)

      assert result == nil
    end

    test "returns fallback when key is not found and fallback argument is passed" do
      map = %{
        hello: "world"
      }

      field = "new key"
      fallback = "fallback value"

      result = Artemis.Helpers.indifferent_get(map, field, fallback)

      assert result == fallback
    end

    test "raises an exception when matching atom and bitstring keys are found" do
      map = %{
        :hello => "as atom",
        "hello" => "as string"
      }

      field = "hello"

      assert_raise ArgumentError, fn ->
        Artemis.Helpers.indifferent_get(map, field)
      end
    end
  end

  describe "indifferent_put" do
    test "updates bitstring keys when given a bitstring field name" do
      map = %{
        "hello" => "world"
      }

      field = "hello"
      value = "updated"

      result = Artemis.Helpers.indifferent_put(map, field, value)

      expected = %{
        "hello" => "updated"
      }

      assert result == expected
    end

    test "updates bitstring keys when given an atom field name" do
      map = %{
        "hello" => "world"
      }

      field = :hello
      value = "updated"

      result = Artemis.Helpers.indifferent_put(map, field, value)

      expected = %{
        "hello" => "updated"
      }

      assert result == expected
    end

    test "updates atom keys when given a bitstring field name" do
      map = %{
        hello: "world"
      }

      field = "hello"
      value = "updated"

      result = Artemis.Helpers.indifferent_put(map, field, value)

      expected = %{
        hello: "updated"
      }

      assert result == expected
    end

    test "updates atom keys when given an atom field name" do
      map = %{
        hello: "world"
      }

      field = :hello
      value = "updated"

      result = Artemis.Helpers.indifferent_put(map, field, value)

      expected = %{
        hello: "updated"
      }

      assert result == expected
    end

    test "creates a new key when field is not found" do
      map = %{
        hello: "world"
      }

      field = "new key"
      value = "new value"

      result = Artemis.Helpers.indifferent_put(map, field, value)

      expected = %{
        :hello => "world",
        "new key" => "new value"
      }

      assert result == expected
    end

    test "raises an exception when matching atom and bitstring keys are found" do
      map = %{
        :hello => "as atom",
        "hello" => "as string"
      }

      field = "hello"
      value = "updated"

      assert_raise ArgumentError, fn ->
        Artemis.Helpers.indifferent_put(map, field, value)
      end
    end
  end
end
