defmodule ArtemisWeb.PermissionView do
  use ArtemisWeb, :view

  import ArtemisWeb.UserAccess

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.DeletePermission.call_many(&1, &2),
        authorize: &has?(&1, "permissions:delete"),
        key: "delete",
        label: "Delete Permissions"
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

  def get_bulk_action(key, user) do
    Enum.find_value(available_bulk_actions(), fn entry ->
      entry.key == key && entry.authorize.(user) && entry.action
    end)
  end

  # Data Table

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Name", "name"},
      {"Slug", "slug"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "name" => [
        label: fn _conn -> "Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "name", "Name")
        end,
        value: fn _conn, row -> row.name end,
        value_html: fn conn, row ->
          link(row.name, to: Routes.permission_path(conn, :show, row))
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
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "permissions:show"),
        link: link("Show", to: Routes.permission_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "permissions:update"),
        link: link("Edit", to: Routes.permission_path(conn, :edit, row))
      ],
      [
        verify: has?(conn, "permissions:delete"),
        link:
          link("Delete",
            to: Routes.permission_path(conn, :delete, row),
            method: :delete,
            data: [confirm: "Are you sure?"]
          )
      ]
    ]

    Enum.reduce(allowed_actions, [], fn action, acc ->
      case Keyword.get(action, :verify) do
        true -> [acc | Keyword.get(action, :link)]
        _ -> acc
      end
    end)
  end
end
