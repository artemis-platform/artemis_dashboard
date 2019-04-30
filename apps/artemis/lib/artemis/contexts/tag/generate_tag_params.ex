defmodule Artemis.GenerateTagParams do
  @moduledoc """
  Generates missing tag attributes
  """

  def call(params, record \\ nil) do
    params
    |> Artemis.Helpers.keys_to_strings()
    |> add_slug(record)
  end

  defp add_slug(params, record) do
    slug = generate_slug(params, record)

    Map.put(params, "slug", slug)
  end

  defp generate_slug(%{"slug" => "", "name" => name}, _), do: Artemis.Helpers.generate_slug(name)
  defp generate_slug(%{"slug" => nil, "name" => name}, _), do: Artemis.Helpers.generate_slug(name)
  defp generate_slug(%{"slug" => value}, _), do: value
  defp generate_slug(%{"name" => name}, _), do: Artemis.Helpers.generate_slug(name)
  defp generate_slug(_, record) when is_map(record), do: record.slug
  defp generate_slug(_, _), do: nil
end
