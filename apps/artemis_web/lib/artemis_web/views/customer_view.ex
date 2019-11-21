defmodule ArtemisWeb.CustomerView do
  use ArtemisWeb, :view

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
      ],
      [
        verify: has?(conn, "customers:delete"),
        link:
          link("Delete",
            to: Routes.customer_path(conn, :delete, row),
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
