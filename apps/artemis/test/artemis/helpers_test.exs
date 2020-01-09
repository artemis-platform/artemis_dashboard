defmodule Artemis.HelpersTest do
  use Artemis.DataCase, async: true

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
end
