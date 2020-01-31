defmodule ArtemisWeb.SystemTaskView do
  use ArtemisWeb, :view

  # Data Table

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Description", "description"},
      {"Name", "name"},
      {"Type", "type"}
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
        value: fn _conn, row -> row.description end
      ],
      "name" => [
        label: fn _conn -> "Name" end,
        value: fn _conn, row -> row.name end,
        value_html: fn conn, row ->
          case has?(conn, "system-tasks:create") do
            true -> link(row.name, to: Routes.system_task_path(conn, :new, type: row.type))
            false -> row.name
          end
        end
      ],
      "type" => [
        label: fn _conn -> "Type" end,
        value: fn _conn, row -> row.type end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "system-tasks:create"),
        link: link("New", to: Routes.system_task_path(conn, :new, type: row.type))
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
