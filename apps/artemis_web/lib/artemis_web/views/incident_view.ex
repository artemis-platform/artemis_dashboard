defmodule ArtemisWeb.IncidentView do
  use ArtemisWeb, :view

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.DeleteIncident.call_many(&1, &2),
        authorize: &has?(&1, "incidents:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Incidents"
      }
    ]
  end

  def allowed_bulk_actions(user) do
    Enum.reduce(available_bulk_actions(), [], fn entry, acc ->
      case entry.authorize.(user) do
        true -> [entry | acc]
        false -> acc
      end
    end)
  end

  # Helpers

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
