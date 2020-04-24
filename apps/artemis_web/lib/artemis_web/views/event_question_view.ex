defmodule ArtemisWeb.EventQuestionView do
  use ArtemisWeb, :view

  # Data Table

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Title", "title"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "title" => [
        label: fn _conn -> "Title" end,
        label_html: fn conn ->
          sortable_table_header(conn, "title", "Title")
        end,
        value: fn _conn, row -> row.title end,
        value_html: fn conn, row ->
          case has?(conn, "event-questions:show") do
            true -> link(row.title, to: Routes.event_question_path(conn, :show, row.event_template, row))
            false -> row.title
          end
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "event-questions:show"),
        link: link("Show", to: Routes.event_question_path(conn, :show, row.event_template, row))
      ],
      [
        verify: has?(conn, "event-questions:update"),
        link: link("Edit", to: Routes.event_question_path(conn, :edit, row.event_template, row))
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

  # Helpers

  def render_show_link(_conn, nil), do: nil

  def render_show_link(conn, record) do
    link(record.title, to: Routes.event_question_path(conn, :show, record.event_template, record))
  end
end
