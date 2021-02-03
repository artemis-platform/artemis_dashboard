defmodule ArtemisWeb.KeyValueView do
  use ArtemisWeb, :view

  @default_display_size_limit_index 2_500
  @default_display_size_limit_show 5_000

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.DeleteKeyValue.call_many(&1, &2),
        authorize: &has?(&1, "key-values:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Key Values"
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
      {"ID", "id"},
      {"Key", "key"},
      {"Size", "Size"},
      {"Value", "value"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "expire_at" => [
        label: fn _conn -> "Expire At" end,
        label_html: fn conn ->
          sortable_table_header(conn, "expire_at", "Expire At")
        end,
        value: fn _conn, row -> row.expire_at end,
        value_html: fn _conn, row ->
          render_table_entry(
            render_date_time_with_seconds_short(row.expire_at),
            render_relative_time(row.expire_at)
          )
        end
      ],
      "id" => [
        label: fn _conn -> "ID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "id", "ID")
        end,
        value: fn _conn, row -> row.id end,
        value_html: fn conn, row ->
          shortened_id = String.slice(row.id, 0, 8)

          case has?(conn, "key-values:show") do
            true -> link(shortened_id, to: Routes.key_value_path(conn, :show, row))
            false -> shortened_id
          end
        end
      ],
      "inserted_at" => [
        label: fn _conn -> "Inserted At" end,
        label_html: fn conn ->
          sortable_table_header(conn, "inserted_at", "Inserted At")
        end,
        value: fn _conn, row -> row.inserted_at end,
        value_html: fn _conn, row ->
          render_table_entry(
            render_date_time_with_seconds_short(row.inserted_at),
            render_relative_time(row.inserted_at)
          )
        end
      ],
      "key" => [
        label: fn _conn -> "Key" end,
        label_html: fn conn ->
          sortable_table_header(conn, "key", "Key")
        end,
        value: fn _conn, row -> row.key end,
        value_html: fn _conn, row ->
          content_tag(:pre) do
            content_tag(:code) do
              render_field_if_under_size_limit(row, :key, size_limit: @default_display_size_limit_index)
            end
          end
        end
      ],
      "size" => [
        label: fn _conn -> "Size" end,
        label_html: fn conn ->
          sortable_table_header(conn, "size", "Size")
        end,
        value: fn _conn, row -> row.size end,
        value_html: fn _conn, row -> "#{row.size} bytes" end
      ],
      "updated_at" => [
        label: fn _conn -> "Updated At" end,
        label_html: fn conn ->
          sortable_table_header(conn, "updated_at", "Updated At")
        end,
        value: fn _conn, row -> row.updated_at end,
        value_html: fn _conn, row ->
          render_table_entry(
            render_date_time_with_seconds_short(row.updated_at),
            render_relative_time(row.updated_at)
          )
        end
      ],
      "value" => [
        label: fn _conn -> "Value" end,
        label_html: fn conn ->
          sortable_table_header(conn, "value", "Value")
        end,
        value: fn _conn, row -> row.value end,
        value_html: fn _conn, row ->
          content_tag(:pre) do
            content_tag(:code) do
              render_field_if_under_size_limit(row, :value, size_limit: @default_display_size_limit_index)
            end
          end
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "key-values:show"),
        link: link("Show", to: Routes.key_value_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "key-values:update"),
        link: link("Edit", to: Routes.key_value_path(conn, :edit, row))
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
  Return byte size of given field
  """
  def get_field_size(record, field) do
    case field do
      :value ->
        Map.get(record, :size)

      _ ->
        record
        |> Map.get(field)
        |> Artemis.KeyValue.encode()
        |> byte_size()
    end
  end

  @doc """
  Returns a boolean if the field is unde the size limit
  """
  def field_under_size_limit?(record, field, options \\ []) do
    size = get_field_size(record, field)
    size_limit = Keyword.get(options, :size_limit) || get_default_display_size_limit()

    size < size_limit
  end

  @doc """
  Render field if below display size limit
  """
  def render_field_if_under_size_limit(record, field, options \\ []) do
    case field_under_size_limit?(record, field, options) do
      true ->
        record
        |> Map.get(field)
        |> inspect(pretty: true)

      false ->
        "Over display limit"
    end
  end

  @doc """
  Return the default size limit for displaying a binary value
  """
  def get_default_display_size_limit(), do: @default_display_size_limit_show

  @doc """
  Get display size limit from conn query param `?view[size_limit]=<value>`
  """
  def get_display_size_limit(conn) do
    Artemis.Helpers.deep_get(conn.query_params, ["view", "size_limit"])
  end

  @doc """
  Render a display field button that increases the display size_limit
  """
  def render_display_field_action(conn, record) do
    key_size = get_field_size(record, :key) || 0
    value_size = get_field_size(record, :key) || 0
    new_size_limit = Enum.max([key_size, value_size]) + 1

    view_query_params = %{
      size_limit: new_size_limit
    }

    action("View Field",
      to: Routes.key_value_path(conn, :show, record.id, view: view_query_params),
      size: "tiny",
      color: "blue"
    )
  end

  @doc """
  Render a form warning
  """
  def render_form_warning() do
    body = """
    Although Key Values can store any kind of Elixir term, for security reasons
    anything input from the web or API interfaces will be stored as strings and
    never evaluated. Only Elixir applications can store other data types.
    """

    ArtemisWeb.ViewHelper.Notifications.render_notification("info", body: body)
  end

  @doc """
  Determine if record should be modifiable through the form
  """
  def modifiable?(%Artemis.KeyValue{} = record) do
    key_modifiable? = is_bitstring(record.key)
    value_modifiable? = is_bitstring(record.value)

    key_modifiable? && value_modifiable?
  end
end
