defmodule ArtemisWeb.IncidentView do
  use ArtemisWeb, :view

  def render_tags(conn, incident) do
    Enum.map(incident.tags, fn tag ->
      to = Routes.incident_path(conn, :index, filters: %{tags: [tag.slug]})

      content_tag(:div) do
        link(tag.name, to: to)
      end
    end)
  end

  def get_subdomain(), do: Application.fetch_env!(:artemis, :pager_duty)[:subdomain]

  def status_color(%{status: status}) when is_bitstring(status) do
    case String.downcase(status) do
      "resolved" -> "green"
      "acknowledged" -> "yellow"
      "triggered" -> "red"
      true -> nil
    end
  end
  def status_color(_), do: nil
end
