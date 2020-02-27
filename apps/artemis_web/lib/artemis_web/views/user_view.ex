defmodule ArtemisWeb.UserView do
  use ArtemisWeb, :view

  import Artemis.Helpers, only: [keys_to_atoms: 2]
  import ArtemisWeb.UserAccess

  alias Artemis.UserRole

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: fn ids, [request_params, user] ->
          role_id = Map.get(request_params, "add_role_id")
          params = [role_id, request_params, user]

          Artemis.GetOrCreateUserRole.call_many(ids, params)
        end,
        authorize: &has_all?(&1, ["users:access:all", "users:update"]),
        extra_fields: &render_extra_fields_add_role(&1),
        key: "add-role",
        label: "Add Role"
      },
      %BulkAction{
        action: fn ids, [request_params, user] ->
          role_id = Map.get(request_params, "remove_role_id")
          params = [role_id, request_params, user]

          Artemis.GetAndDeleteUserRole.call_many(ids, params)
        end,
        authorize: &has_all?(&1, ["users:access:all", "users:update"]),
        extra_fields: &render_extra_fields_remove_role(&1),
        key: "remove-role",
        label: "Remove Role"
      },
      %BulkAction{
        action: fn ids, [request_params, user] ->
          team_id = Map.get(request_params, "add_team_id")
          params = [team_id, request_params, user]

          Artemis.GetOrCreateUserTeam.call_many(ids, params)
        end,
        authorize: &has_all?(&1, ["users:access:all", "users:update"]),
        extra_fields: &render_extra_fields_add_team(&1),
        key: "add-team",
        label: "Add Team"
      },
      %BulkAction{
        action: fn ids, [request_params, user] ->
          team_id = Map.get(request_params, "remove_team_id")
          params = [team_id, request_params, user]

          Artemis.GetAndDeleteUserTeam.call_many(ids, params)
        end,
        authorize: &has_all?(&1, ["users:access:all", "users:update"]),
        extra_fields: &render_extra_fields_remove_team(&1),
        key: "remove-team",
        label: "Remove Team"
      },
      %BulkAction{
        action: &Artemis.DeleteUser.call_many(&1, &2),
        authorize: &has?(&1, "users:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Users"
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

  defp render_extra_fields_add_role(data) do
    render_extra_field_select_role(data, "add_role_id")
  end

  defp render_extra_fields_remove_role(data) do
    render_extra_field_select_role(data, "remove_role_id")
  end

  defp render_extra_field_select_role(data, name) do
    roles = Keyword.get(data, :roles)
    label_tag = content_tag(:label, "Roles")

    select_tag =
      content_tag(:select, class: "enhanced", name: name, placeholder: "Roles") do
        Enum.map(roles, fn [key: key, value: value] ->
          content_tag(:option, value: value) do
            key
          end
        end)
      end

    content_tag(:div, class: "field") do
      [label_tag, select_tag]
    end
  end

  defp render_extra_fields_add_team(data) do
    render_extra_field_select_team(data, "add_team_id")
  end

  defp render_extra_fields_remove_team(data) do
    render_extra_field_select_team(data, "remove_team_id")
  end

  defp render_extra_field_select_team(data, name) do
    teams = Keyword.get(data, :teams)
    label_tag = content_tag(:label, "Teams")

    select_tag =
      content_tag(:select, class: "enhanced", name: name, placeholder: "Teams") do
        Enum.map(teams, fn [key: key, value: value] ->
          content_tag(:option, value: value) do
            key
          end
        end)
      end

    content_tag(:div, class: "field") do
      [label_tag, select_tag]
    end
  end

  # Data Table

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Email", "email"},
      {"First Name", "first_name"},
      {"Last Login", "last_log_in_at"},
      {"Last Name", "last_name"},
      {"Name", "name"},
      {"Roles", "roles"},
      {"Teams", "teams"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "email" => [
        label: fn _conn -> "Email" end,
        label_html: fn conn ->
          sortable_table_header(conn, "email", "Email")
        end,
        value: fn _conn, row -> row.email end
      ],
      "first_name" => [
        label: fn _conn -> "First Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "first_name", "First Name")
        end,
        value: fn _conn, row -> row.first_name end
      ],
      "last_log_in_at" => [
        label: fn _conn -> "Last Login" end,
        label_html: fn conn ->
          sortable_table_header(conn, "last_log_in_at", "Last Login")
        end,
        value: fn _conn, row -> row.last_log_in_at end
      ],
      "last_name" => [
        label: fn _conn -> "Last Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "last_name", "Last Name")
        end,
        value: fn _conn, row -> row.last_name end
      ],
      "name" => [
        label: fn _conn -> "Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "name", "Name")
        end,
        value: fn _conn, row -> row.name end,
        value_html: fn conn, row ->
          case has?(conn, "users:show") do
            true -> link(row.name, to: Routes.user_path(conn, :show, row))
            false -> row.name
          end
        end
      ],
      "roles" => [
        label: fn _conn -> "Roles" end,
        value: fn _conn, row ->
          row.roles
          |> Enum.map(&Map.get(&1, :name))
          |> Enum.sort()
          |> Enum.join(", ")
        end,
        value_html: fn _conn, row ->
          row.roles
          |> Enum.map(&Map.get(&1, :name))
          |> Enum.sort()
          |> Enum.map(&content_tag(:div, &1))
        end
      ],
      "teams" => [
        label: fn _conn -> "Teams" end,
        value: fn _conn, row ->
          row.teams
          |> Enum.map(&Map.get(&1, :name))
          |> Enum.sort()
          |> Enum.join(", ")
        end,
        value_html: fn _conn, row ->
          row.teams
          |> Enum.map(&Map.get(&1, :name))
          |> Enum.sort()
          |> Enum.map(&content_tag(:div, &1))
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "users:show"),
        link: link("Show", to: Routes.user_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "users:update"),
        link: link("Edit", to: Routes.user_path(conn, :edit, row))
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
  Returns a matching `user_role` record based on the passed `role.id` match value.

  The `user_role` data could come from:

  1. The existing record in the database.
  2. The existing form data.

  If the form has not been submitted, it uses the existing record data in the database.

  Once the form is submitted, the existing form data takes precedence. This
  ensures new values are not lost when the form is reloaded after an error.
  """
  def find_user_role(match, form, record) do
    existing_user_roles = record.user_roles

    submitted_user_roles =
      case form.params["user_roles"] do
        nil -> nil
        values -> Enum.map(values, &struct(UserRole, keys_to_atoms(&1, [])))
      end

    user_roles = submitted_user_roles || existing_user_roles

    Enum.find(user_roles, fn %{role_id: role_id} ->
      role_id =
        case is_bitstring(role_id) do
          true -> String.to_integer(role_id)
          _ -> role_id
        end

      role_id == match
    end)
  end
end
