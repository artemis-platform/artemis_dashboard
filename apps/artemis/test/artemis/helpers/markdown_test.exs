defmodule Artemis.Helpers.MarkdownTest do
  use Artemis.DataCase

  alias Artemis.Helpers.Markdown

  describe "to_html!" do
    test "returns error when passed an invalid data type" do
      value = %{invalid: "type"}

      assert_raise ArgumentError, fn () ->
        Markdown.to_html!(value)
      end
    end

    test "accepts an empty string" do
      value = ""

      result = Markdown.to_html!(value)

      assert result == ""
    end

    test "converts simple markdown" do
      value = "# Hello World"

      result = Markdown.to_html!(value)

      assert result == "<h1>Hello World</h1>\n"
    end

    test "supports checklists - unchecked" do
      value = "- [ ] Hello World"

      result = Markdown.to_html!(value)

      assert result == "<p> <input type=\"checkbox\" disabled> Hello World</p>\n"
    end

    test "supports checklists - checked" do
      value = "- [x] Hello World"

      result = Markdown.to_html!(value)

      assert result == "<p> <input type=\"checkbox\" checked=\"checked\" disabled> Hello World</p>\n"

      # With uppercase X

      value = "- [X] Hello World"

      result = Markdown.to_html!(value)

      assert result == "<p> <input type=\"checkbox\" checked=\"checked\" disabled> Hello World</p>\n"
    end
  end
end
