defmodule ArtemisWeb.JobView do
  use ArtemisWeb, :view

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.DeleteJob.call_many(&1, &2),
        authorize: &has?(&1, "jobs:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Jobs"
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
      {"Completed At", "completed_at"},
      {"Inserted At", "inserted_at"},
      {"ID", "id"},
      {"Name", "name"},
      {"Started At", "started_at"},
      {"Status", "status"},
      {"Type", "type"},
      {"Updated At", "updated_at"},
      {"UUID", "uuid"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "completed_at" => [
        label: fn _conn -> "Completed At" end,
        label_html: fn conn ->
          sortable_table_header(conn, "completed_at", "Completed At")
        end,
        value: fn _conn, row -> row.completed_at end,
        value_html: fn _conn, row ->
          render_date_time_with_seconds(row.completed_at)
        end
      ],
      "inserted_at" => [
        label: fn _conn -> "Inserted At" end,
        label_html: fn conn ->
          sortable_table_header(conn, "inserted_at", "Inserted At")
        end,
        value: fn _conn, row -> row.inserted_at end,
        value_html: fn _conn, row ->
          render_date_time_with_seconds(row.inserted_at)
        end
      ],
      "id" => [
        label: fn _conn -> "ID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "_id", "ID")
        end,
        value: fn _conn, row -> row._id end,
        value_html: fn conn, row ->
          case has?(conn, "jobs:show") do
            true -> link(row._id, to: Routes.job_path(conn, :show, row._id))
            false -> row._id
          end
        end
      ],
      "name" => [
        label: fn _conn -> "Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "name", "Name")
        end,
        value: fn _conn, row -> row.name end
      ],
      "started_at" => [
        label: fn _conn -> "Started At" end,
        label_html: fn conn ->
          sortable_table_header(conn, "started_at", "Started At")
        end,
        value: fn _conn, row -> row.started_at end,
        value_html: fn _conn, row ->
          render_date_time_with_seconds(row.started_at)
        end
      ],
      "status" => [
        label: fn _conn -> "Status" end,
        label_html: fn conn ->
          sortable_table_header(conn, "status", "Status")
        end,
        value: &status_row_value/2,
        value_html: &status_row_value_html/2
      ],
      "type" => [
        label: fn _conn -> "Type" end,
        label_html: fn conn ->
          sortable_table_header(conn, "type", "Type")
        end,
        value: fn _conn, row -> row.type end
      ],
      "updated_at" => [
        label: fn _conn -> "Updated At" end,
        label_html: fn conn ->
          sortable_table_header(conn, "updated_at", "Updated At")
        end,
        value: fn _conn, row -> row.updated_at end,
        value_html: fn _conn, row ->
          render_date_time_with_seconds(row.updated_at)
        end
      ],
      "uuid" => [
        label: fn _conn -> "UUID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "uuid", "UUID")
        end,
        value: fn _conn, row -> row.uuid end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "jobs:show"),
        link: link("Show", to: Routes.job_path(conn, :show, row._id))
      ],
      [
        verify: has?(conn, "jobs:update"),
        link: link("Edit", to: Routes.job_path(conn, :edit, row._id))
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

  defp status_row_value(_conn, row), do: row.status || "Undefined"

  defp status_row_value_html(conn, row) do
    body = status_row_value(conn, row)
    class = "status-label #{status_color(row)}"

    content_tag(:span, body, class: class)
  end

  @doc """
  Render status
  """
  def render_status(record) do
    color = status_color(record)
    status = Map.get(record, :status) || "Undefined"

    content_tag(:span, status, class: "status-label #{color}")
  end

  @doc """
  Return a color value based on status
  """
  def status_color(%{status: status}) when is_bitstring(status) do
    case String.downcase(status) do
      "running" -> "blue"
      "completed" -> "green"
      "error" -> "red"
      _ -> nil
    end
  end

  def status_color(_), do: nil

  @doc """
  Render elapsed time
  """
  def render_elapsed_time(%{started_at: nil}), do: nil

  def render_elapsed_time(%{status: "Running"} = job) do
    {:ok, start} = DateTime.from_unix(job.started_at)

    render_time_duration(start, Timex.now())
  end

  def render_elapsed_time(%{status: "Completed"} = job) do
    {:ok, first} = DateTime.from_unix(job.started_at)
    {:ok, last} = DateTime.from_unix(job.completed_at)

    render_time_duration(first, last)
  rescue
    _ -> nil
  end

  def render_elapsed_time(_), do: nil
end
