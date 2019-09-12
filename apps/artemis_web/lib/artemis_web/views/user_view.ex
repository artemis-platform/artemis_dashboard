defmodule ArtemisWeb.UserView do
  use ArtemisWeb, :view

  import Artemis.Helpers, only: [keys_to_atoms: 2]
  import ArtemisWeb.UserAccess

  alias Artemis.UserRole

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Email", "email"},
      {"First Name", "first_name"},
      {"Last Login", "last_log_in_at"},
      {"Last Name", "last_name"},
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
          link(row.name, to: Routes.user_path(conn, :show, row))
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
      ],
      [
        verify: has?(conn, "users:delete"),
        link:
          link("Delete",
            to: Routes.user_path(conn, :delete, row),
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
