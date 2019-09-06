defmodule ArtemisWeb.HttpRequestLogView do
  use ArtemisWeb, :view

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Created At", "inserted_at"},
      {"Endpoint", "endpoint"},
      {"ID", "id"},
      {"Node", "node"},
      {"Path", "path"},
      {"Query String", "query_string"},
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
      "id" => [
        label: fn _conn -> "ID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "id", "ID")
        end,
        value: fn _conn, row -> row.id end,
        value_html: fn conn, row ->
          case has?(conn, "http-request-logs:show") do
            true -> link(row.id, to: Routes.http_request_log_path(conn, :show, row.id))
            false -> row.id
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
      "endpoint" => [
        label: fn _conn -> "Endpoint" end,
        label_html: fn conn ->
          sortable_table_header(conn, "endpoint", "Endpoint")
        end,
        value: fn _conn, row -> row.endpoint end
      ],
      "node" => [
        label: fn _conn -> "Node" end,
        label_html: fn conn ->
          sortable_table_header(conn, "node", "Node")
        end,
        value: fn _conn, row -> row.node end
      ],
      "path" => [
        label: fn _conn -> "Path" end,
        label_html: fn conn ->
          sortable_table_header(conn, "path", "Path")
        end,
        value: fn _conn, row -> row.path end
      ],
      "query_string" => [
        label: fn _conn -> "Query String" end,
        label_html: fn conn ->
          sortable_table_header(conn, "query_string", "Query String")
        end,
        value: fn _conn, row -> row.query_string end
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
        verify: has?(conn, "http-request-logs:show"),
        link: link("Show", to: Routes.http_request_log_path(conn, :show, row.id))
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
