defmodule ArtemisWeb.TeamView do
  use ArtemisWeb, :view

  import Artemis.Helpers, only: [keys_to_atoms: 2]

  alias Artemis.Permission

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.DeleteTeam.call_many(&1, &2),
        authorize: &has?(&1, "teams:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Teams"
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

  # Data Table

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Description", "description"},
      {"Name", "name"},
      {"Slug", "slug"},
      {"User Count", "user_count"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "description" => [
        label: fn _conn -> "Description" end,
        label_html: fn conn ->
          sortable_table_header(conn, "description", "Description")
        end,
        value: fn _conn, row -> row.description end
      ],
      "name" => [
        label: fn _conn -> "Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "name", "Name")
        end,
        value: fn _conn, row -> row.name end,
        value_html: fn conn, row ->
          case has?(conn, "teams:show") do
            true -> link(row.name, to: Routes.team_path(conn, :show, row))
            false -> row.name
          end
        end
      ],
      "slug" => [
        label: fn _conn -> "Slug" end,
        label_html: fn conn ->
          sortable_table_header(conn, "slug", "Slug")
        end,
        value: fn _conn, row -> row.slug end,
        value_html: fn _conn, row ->
          content_tag(:code, row.slug)
        end
      ],
      "user_count" => [
        label: fn _conn -> "Total Users" end,
        value: fn _conn, row -> row.user_count end,
        value_html: fn conn, row ->
          case has?(conn, "teams:show") do
            true -> link(row.user_count, to: Routes.team_path(conn, :show, row) <> "#link-users")
            false -> row.user_count
          end
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "teams:show"),
        link: link("Show", to: Routes.team_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "teams:update"),
        link: link("Edit", to: Routes.team_path(conn, :edit, row))
      ]
    ]

    content_tag(:div, class: "actions") do
      Enum.reduce(allowed_actions, [], fn action, acc ->
        case Keyword.get(action, :verify) do
          true -> [acc | Keyword.get(action, :link)]
          _ -> acc
        end
      end)
    end
  end

  @doc """
  Returns a matching `permission` record based on the passed `permission.id` match value.

  The `permission` data could come from:

  1. The existing record in the database.
  2. The existing form data.

  If the form has not been submitted, it uses the existing record data in the database.

  Once the form is submitted, the existing form data takes precedence. This
  ensures new values are not lost when the form is reloaded after an error.
  """
  def find_permission(match, form, record) do
    existing_permissions = record.permissions

    submitted_permissions =
      case form.params["permissions"] do
        nil -> nil
        values -> Enum.map(values, &struct(Permission, keys_to_atoms(&1, [])))
      end

    permissions = submitted_permissions || existing_permissions

    Enum.find(permissions, fn %{id: id} ->
      id =
        case is_bitstring(id) do
          true -> String.to_integer(id)
          _ -> id
        end

      id == match
    end)
  end
end
