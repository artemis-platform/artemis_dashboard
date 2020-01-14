defmodule ArtemisWeb.CustomerView do
  use ArtemisWeb, :view

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.DeleteCustomer.call_many(&1, &2),
        authorize: &has?(&1, "customers:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Customers"
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
      {"Name", "name"}
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
          case has?(conn, "customers:show") do
            true -> link(row.name, to: Routes.customer_path(conn, :show, row))
            false -> row.name
          end
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "customers:show"),
        link: link("Show", to: Routes.customer_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "customers:update"),
        link: link("Edit", to: Routes.customer_path(conn, :edit, row))
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
end
