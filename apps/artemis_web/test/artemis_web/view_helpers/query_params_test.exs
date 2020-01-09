defmodule ArtemisWeb.ViewHelper.QueryParamsTest do
  use ArtemisWeb.ConnCase, async: true

  alias ArtemisWeb.ViewHelper.QueryParams

  describe "update_query_params" do
    test "returns an empty map when given empty values" do
      current_params = %{}
      update_params = %{}

      result = QueryParams.update_query_params(current_params, update_params)

      assert result == %{}
    end

    test "updates a new value" do
      current_params = %{}

      update_params = %{
        "hello" => "world"
      }

      result = QueryParams.update_query_params(current_params, update_params)

      assert result == update_params
    end

    test "converts atom keys to strings" do
      current_params = %{}

      update_params = %{
        hello: "world"
      }

      result = QueryParams.update_query_params(current_params, update_params)

      expected = %{
        "hello" => "world"
      }

      assert result == expected
    end

    test "accepts keyword lists" do
      current_params = %{}

      update_params = [
        hello: "world"
      ]

      result = QueryParams.update_query_params(current_params, update_params)

      expected = %{
        "hello" => "world"
      }

      assert result == expected
    end

    test "updates existing values" do
      current_params = %{
        "hello" => "world"
      }

      update_params = %{
        "hello" => "update"
      }

      result = QueryParams.update_query_params(current_params, update_params)

      assert result == update_params
    end

    test "keeps existing values" do
      current_params = %{
        "hello" => "world",
        "other" => "value"
      }

      update_params = %{
        "hello" => "update"
      }

      result = QueryParams.update_query_params(current_params, update_params)

      expected = %{
        "hello" => "update",
        "other" => "value"
      }

      assert result == expected
    end

    test "parses nested params" do
      current_params = %{
        "hello" => "world"
      }

      update_params = %{
        "nested" => %{
          "hello" => "new"
        }
      }

      result = QueryParams.update_query_params(current_params, update_params)

      expected = %{
        "hello" => "world",
        "nested" => %{
          "hello" => "new"
        }
      }

      assert result == expected
    end

    test "parses multiple nested params" do
      current_params = %{}

      update_params = %{
        "nested" => %{
          "hello" => "world",
          "other" => "value"
        }
      }

      result = QueryParams.update_query_params(current_params, update_params)

      assert result == update_params
    end

    test "merges nested params" do
      current_params = %{
        "nested" => %{
          "hello" => "world"
        }
      }

      update_params = %{
        "nested" => %{
          "other" => "value"
        }
      }

      result = QueryParams.update_query_params(current_params, update_params)

      expected = %{
        "nested" => %{
          "hello" => "world",
          "other" => "value"
        }
      }

      assert result == expected
    end

    test "updates nested params" do
      current_params = %{
        "nested" => %{
          "hello" => "world"
        }
      }

      update_params = %{
        "nested" => %{
          "hello" => "updated"
        }
      }

      result = QueryParams.update_query_params(current_params, update_params)

      assert result == update_params
    end

    test "removes nil values" do
      current_params = %{
        "hello" => "world"
      }

      update_params = %{
        "hello" => nil
      }

      result = QueryParams.update_query_params(current_params, update_params)

      assert result == %{}
    end

    test "removes nested nil values" do
      current_params = %{
        "nested" => %{
          "hello" => "world"
        }
      }

      update_params = %{
        "nested" => %{
          "hello" => nil
        }
      }

      result = QueryParams.update_query_params(current_params, update_params)

      assert result == %{}
    end

    test "helper test" do
      map = %{
        hello: "world",
        nested: %{example: "value", hello: "world"}
      }

      result = Artemis.Helpers.deep_drop_by_value(map, "world")

      expected = %{
        nested: %{example: "value"}
      }

      assert result == expected
    end
  end
end
