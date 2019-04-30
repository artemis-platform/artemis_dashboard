defmodule Artemis.Helpers.Markdown do
  @checked_box "<input type=\"checkbox\" checked=\"checked\" disabled>"
  @unchecked_box "<input type=\"checkbox\" disabled>"
  @regex_checked ~r/\r\n[-,*,+] \[[X,x]\]|^[-,*,+] \[[X,x]\]/
  @regex_checked_with_text ~r/\r\n[-,*,+] \[[X,x]\] \S+|^[-,*,+] \[[X,x]\] \S+/
  @regex_unchecked ~r/^[-,*,+] \[\s\]|\r\n[-,*,+] \[\s\]/
  @regex_unchecked_with_text ~r/^[-,*,+]\s\[\s\]\s\S+|\r\n[-,*,+]\s\[\s\]\s\S+/

  @doc """
  Convert markdown test to sanitized HTML
  """
  def to_html!(value) do
    value
    |> HtmlSanitizeEx.basic_html()
    |> convert_checkboxes()
    |> Earmark.as_html!(%Earmark.Options{breaks: true})
  end

  defp convert_checkboxes(value) do
    value
    |> replace_checked
    |> replace_unchecked
  end

  def replace_checked(value) do
    case String.match?(value, @regex_checked_with_text) do
      true -> String.replace(value, @regex_checked, "\r\n " <> @checked_box)
      false -> value
    end
  end

  def replace_unchecked(value) do
    case String.match?(value, @regex_unchecked_with_text) do
      true -> String.replace(value, @regex_unchecked, "\r\n " <> @unchecked_box)
      false -> value
    end
  end
end
