defmodule ArtemisNotify.ViewHelper.Slack do
  @doc """
  Converts HTML bitstring to slack markdown
  """
  def convert_html_to_slack_markdown!(html) do
    html
    |> Floki.parse_fragment!()
    |> strip_html_tags()
    |> Floki.text()
  end

  defp strip_html_tags(html_tree) do
    Enum.map(html_tree, &update_tag(&1))
  end

  defp update_tag(text) when is_bitstring(text), do: text
  defp update_tag({"a", attributes, children}), do: update_anchor_tag(attributes, children)
  defp update_tag({"em", _, children}), do: {"span", [], ["_#{Floki.text(strip_html_tags(children))}_"]}
  defp update_tag({"strong", _, children}), do: {"span", [], ["*#{Floki.text(strip_html_tags(children))}*"]}
  defp update_tag({_, _, children}), do: {"span", [], strip_html_tags(children)}

  defp update_anchor_tag(attributes, children) do
    href =
      attributes
      |> Enum.find(&(elem(&1, 0) == "href"))
      |> elem(1)

    {"span", [], ["<#{href}|#{Floki.text(strip_html_tags(children))}>"]}
  end
end
