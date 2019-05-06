defmodule Artemis.Helpers.Markdown do
  @checked_box "- <input type=\"checkbox\" checked=\"checked\">"
  @unchecked_box "- <input type=\"checkbox\">"
  @regex_checked ~r/[-,*,+] \[[X,x]\]/
  @regex_checked_with_text ~r/^[-,*,+] \[[X,x]\] \S+|\n[-,*,+] \[[X,x]\] \S+|\r\n[-,*,+] \[[X,x]\] \S+/
  @regex_unchecked ~r/[-,*,+] \[\s\]/
  @regex_unchecked_with_text ~r/^[-,*,+]\s\[\s\]\s\S+|\n[-,*,+]\s\[\s\]\s\S+|\r\n[-,*,+]\s\[\s\]\s\S+/

  @doc """
  Convert markdown test to sanitized HTML
  """
  def to_html!(value, options \\ []) do
    value
    |> sanitize_html(options)
    |> convert_checkboxes()
    |> Earmark.as_html!()
  end

  defp sanitize_html(value, sanitize: true), do: HtmlSanitizeEx.basic_html(value)
  defp sanitize_html(value, _), do: value

  defp convert_checkboxes(value) do
    value
    |> replace_checked
    |> replace_unchecked
  end

  defp replace_checked(value) do
    case String.match?(value, @regex_checked_with_text) do
      true -> String.replace(value, @regex_checked, @checked_box)
      false -> value
    end
  end

  defp replace_unchecked(value) do
    case String.match?(value, @regex_unchecked_with_text) do
      true -> String.replace(value, @regex_unchecked, @unchecked_box)
      false -> value
    end
  end
end
