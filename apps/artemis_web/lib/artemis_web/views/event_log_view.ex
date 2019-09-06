defmodule ArtemisWeb.EventLogView do
  use ArtemisWeb, :view

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Action", "action"},
      {"Created At", "inserted_at"},
      {"Resource ID", "resource_id"},
      {"Resource Type", "resource_type"},
      {"Session ID", "session_id"},
      {"User ID", "user_id"},
      {"User Name", "user_name"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "action" => [
        label: fn _conn -> "Action" end,
        label_html: fn conn ->
          sortable_table_header(conn, "action", "Action")
        end,
        value: fn _conn, row -> row.action end,
        value_html: fn conn, row ->
          case has?(conn, "event-logs:show") do
            true -> link(row.action, to: Routes.event_log_path(conn, :show, row.id))
            false -> row.action
          end
        end
      ],
      "inserted_at" => [
        label: fn _conn -> "Created At" end,
        label_html: fn conn ->
          sortable_table_header(conn, "inserted_at", "Created At")
        end,
        value: fn _conn, row -> row.inserted_at end
      ],
      "resource_id" => [
        label: fn _conn -> "Resource ID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "resource_id", "Resource ID")
        end,
        value: fn _conn, row -> row.resource_id end
      ],
      "resource_type" => [
        label: fn _conn -> "Resource Type" end,
        label_html: fn conn ->
          sortable_table_header(conn, "resource_type", "Resource Type")
        end,
        value: fn _conn, row -> row.resource_type end
      ],
      "session_id" => [
        label: fn _conn -> "Session ID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "session_id", "Session ID")
        end,
        value: fn _conn, row -> row.session_id end,
        value_html: fn conn, row ->
          case has?(conn, "sessions:show") && Artemis.Helpers.present?(row.session_id) do
            true -> link(row.session_id, to: Routes.session_path(conn, :show, row.session_id))
            false -> row.session_id
          end
        end
      ],
      "user_id" => [
        label: fn _conn -> "User ID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "user_id", "User ID")
        end,
        value: fn _conn, row -> row.user_id end
      ],
      "user_name" => [
        label: fn _conn -> "User Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "user_name", "User Name")
        end,
        value: fn _conn, row -> row.user_name end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "event-logs:show"),
        link: link("Show", to: Routes.event_log_path(conn, :show, row.id))
      ]
    ]

    Enum.reduce(allowed_actions, [], fn action, acc ->
      case Keyword.get(action, :verify) do
        true ->
          item = content_tag(:div, Keyword.get(action, :link))

          [acc | item]

        _ ->
          acc
      end
    end)
  end
end
