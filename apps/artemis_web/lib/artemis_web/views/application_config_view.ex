defmodule ArtemisWeb.ApplicationConfigView do
  use ArtemisWeb, :view

  # Data Table

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Application", "application_config"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "application_config" => [
        label: fn _conn -> "Application" end,
        value: fn _conn, row -> row end,
        value_html: fn conn, row ->
          case has?(conn, "application-configs:show") do
            true -> link(row, to: Routes.application_config_path(conn, :show, row))
            false -> row
          end
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "application-configs:show"),
        link: link("Show", to: Routes.application_config_path(conn, :show, row))
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
