defmodule ArtemisWeb.TeamMemberView do
  use ArtemisWeb, :view

  # Data Table

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Team", "team"},
      {"Type", "type"},
      {"Updated At", "updated_at"},
      {"User", "user"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "team" => [
        label: fn _conn -> "Team" end,
        value: fn _conn, row -> row.team.name end,
        value_html: fn conn, row ->
          case has?(conn, "teams:show") do
            true -> link(row.team.name, to: Routes.team_path(conn, :show, row.team))
            false -> row.team.name
          end
        end
      ],
      "type" => [
        label: fn _conn -> "Type" end,
        value: fn _conn, row -> row.type end
      ],
      "updated_at" => [
        label: fn _conn -> "Updated At" end,
        value: fn _conn, row -> row.updated_at end
      ],
      "user" => [
        label: fn _conn -> "User" end,
        value: fn _conn, row -> row.user.name end,
        value_html: fn conn, row ->
          case has?(conn, "user-teams:show") do
            true -> link(row.user.name, to: Routes.team_member_path(conn, :show, row.team, row))
            false -> row.user.name
          end
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "user-teams:show"),
        link: link("Show", to: Routes.team_member_path(conn, :show, row.team, row))
      ],
      [
        verify: has?(conn, "user-teams:update"),
        link: link("Edit", to: Routes.team_member_path(conn, :edit, row.team, row))
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
