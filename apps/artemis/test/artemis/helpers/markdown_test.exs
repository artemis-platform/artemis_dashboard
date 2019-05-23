defmodule Artemis.Helpers.MarkdownTest do
  use Artemis.DataCase

  alias Artemis.Helpers.Markdown

  describe "to_html!" do
    test "returns error when passed an invalid data type" do
      value = %{invalid: "type"}

      assert_raise FunctionClauseError, fn ->
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

      assert result == "<ul>\n<li><input type=\"checkbox\"> Hello World\n</li>\n</ul>\n"
    end

    test "supports checklists - checked" do
      value = "- [x] Hello World"

      result = Markdown.to_html!(value)

      assert result == "<ul>\n<li><input type=\"checkbox\" checked=\"checked\"> Hello World\n</li>\n</ul>\n"

      # With uppercase X

      value = "- [X] Hello World"

      result = Markdown.to_html!(value)

      assert result == "<ul>\n<li><input type=\"checkbox\" checked=\"checked\"> Hello World\n</li>\n</ul>\n"
    end
  end
end
