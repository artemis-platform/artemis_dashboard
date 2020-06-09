defmodule ArtemisWeb.ViewHelper.FormTest do
  use ArtemisWeb.ConnCase, async: true

  alias ArtemisWeb.ViewHelper.Form

  describe "select_options" do
    test "returns an empty list when given an empty data set" do
      result = Form.select_options([])

      assert result == []
    end

    test "accepts a simple list of values" do
      data = [
        "one",
        "two",
        "three"
      ]

      result = Form.select_options(data)

      expected = [
        [key: "one", value: "one"],
        [key: "two", value: "two"],
        [key: "three", value: "three"]
      ]

      assert result == expected
    end

    test "removes empty values" do
      data = [
        nil,
        "one",
        nil,
        "two",
        nil
      ]

      result = Form.select_options(data)

      expected = [
        [key: "one", value: "one"],
        [key: "two", value: "two"]
      ]

      assert result == expected
    end

    test "accepts an option to include a blank entry" do
      data = [
        "one",
        "two"
      ]

      options = [
        blank_option: true
      ]

      result = Form.select_options(data, options)

      expected = [
        [key: " ", value: ""],
        [key: "one", value: "one"],
        [key: "two", value: "two"]
      ]

      assert result == expected
    end

    test "raises an exception when required options are missing for maps and keyword lists" do
      data = [
        %{id: 1, body: "one"},
        %{id: 2, body: "two"},
        %{id: "3", body: "three"}
      ]

      # Passing empty options raises an error

      missing_options = []

      assert_raise KeyError, fn ->
        Form.select_options(data, missing_options)
      end

      # The `field` option can be used if the key and value use the same field

      valid_options = [
        field: :body
      ]

      result = Form.select_options(data, valid_options)

      expected = [
        [key: "one", value: "one"],
        [key: "two", value: "two"],
        [key: "three", value: "three"]
      ]

      assert result == expected

      # The `key_field` and `value_field` options can be used if the key and
      # value use different fields

      valid_options = [
        key_field: :body,
        value_field: :id
      ]

      result = Form.select_options(data, valid_options)

      expected = [
        [key: "one", value: 1],
        [key: "two", value: 2],
        [key: "three", value: "3"]
      ]

      assert result == expected
    end

    test "accepts a list of maps" do
      data = [
        %{id: 1, body: "one"},
        %{id: 2, body: "two"},
        %{id: "3", body: "three"}
      ]

      options = [
        key_field: :body,
        value_field: :id
      ]

      result = Form.select_options(data, options)

      expected = [
        [key: "one", value: 1],
        [key: "two", value: 2],
        [key: "three", value: "3"]
      ]

      assert result == expected
    end

    test "accepts a list of keyword lists" do
      data = [
        [id: 1, body: "one"],
        [id: 2, body: "two"],
        [id: "3", body: "three"]
      ]

      options = [
        key_field: :body,
        value_field: :id
      ]

      result = Form.select_options(data, options)

      expected = [
        [key: "one", value: 1],
        [key: "two", value: 2],
        [key: "three", value: "3"]
      ]

      assert result == expected
    end
  end
end
