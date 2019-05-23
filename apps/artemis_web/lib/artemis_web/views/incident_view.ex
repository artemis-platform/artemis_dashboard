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
end
