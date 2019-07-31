defmodule ArtemisWeb.JobView do
  use ArtemisWeb, :view

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Command", "command"},
      {"Dependencies", "deps"},
      {"Doc Type", "zzdoc_type"},
      {"First Run", "first_run"},
      {"ID", "id"},
      {"Instance UUID", "instance_uuid"},
      {"Last Run", "last_run"},
      {"Name", "name"},
      {"Status", "status"},
      {"Task ID", "task_id"},
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
      "command" => [
        label: fn _conn -> "Command" end,
        label_html: fn conn ->
          sortable_table_header(conn, "cmd", "Command")
        end,
        value: fn _conn, row -> row.cmd end
      ],
      "deps" => [
        label: fn _conn -> "Dependencies" end,
        label_html: fn conn ->
          sortable_table_header(conn, "deps", "Dependencies")
        end,
        value: fn _conn, row -> row.deps end
      ],
      "first_run" => [
        label: fn _conn -> "First Run" end,
        label_html: fn conn ->
          sortable_table_header(conn, "first_run", "First Run")
        end,
        value: fn _conn, row -> row.first_run end
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
      "instance_uuid" => [
        label: fn _conn -> "Instance UUID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "instance_uuid", "Instance UUID")
        end,
        value: fn _conn, row -> row.instance_uuid end
      ],
      "last_run" => [
        label: fn _conn -> "Last Run" end,
        label_html: fn conn ->
          sortable_table_header(conn, "last_run", "Last Run")
        end,
        value: fn _conn, row -> row.last_run end
      ],
      "name" => [
        label: fn _conn -> "Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "name", "Name")
        end,
        value: fn _conn, row -> row.name end
      ],
      "status" => [
        label: fn _conn -> "Status" end,
        label_html: fn conn ->
          sortable_table_header(conn, "status", "Status")
        end,
        value: &status_row_value/2,
        value_html: &status_row_value_html/2
      ],
      "task_id" => [
        label: fn _conn -> "Task ID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "task_id", "Task ID")
        end,
        value: fn _conn, row -> row.task_id end
      ],
      "uuid" => [
        label: fn _conn -> "UUID" end,
        label_html: fn conn ->
          sortable_table_header(conn, "uuid", "UUID")
        end,
        value: fn _conn, row -> row.uuid end
      ],
      "zzdoc_type" => [
        label: fn _conn -> "Doc Type" end,
        label_html: fn conn ->
          sortable_table_header(conn, "zzdoc_type", "Doc Type")
        end,
        value: fn _conn, row -> row.zzdoc_type end
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
      ],
      [
        verify: has?(conn, "jobs:delete"),
        link:
          link("Delete",
            to: Routes.job_path(conn, :delete, row._id),
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

  defp status_row_value(_conn, row), do: row.status || "Undefined"

  defp status_row_value_html(conn, row) do
    body = status_row_value(conn, row)
    class = "status-label #{status_color(row)}"

    content_tag(:span, body, class: class)
  end

  @doc """
  Return a color value based on status
  """
  def status_color(%{status: status}) when is_bitstring(status) do
    case String.downcase(status) do
      "completed" -> "green"
      _ -> nil
    end
  end

  def status_color(_), do: nil

  @doc """
  Render elapsed time
  """
  def render_elapsed_time(%{first_run: nil}), do: nil

  def render_elapsed_time(%{status: "Running"} = job) do
    {:ok, start} = DateTime.from_unix(job.first_run)

    get_duration(start, Timex.now())
  end

  def render_elapsed_time(%{status: "Completed"} = job) do
    {:ok, first} = DateTime.from_unix(job.first_run)
    {:ok, last} = DateTime.from_unix(job.last_run)

    get_duration(first, last)
  rescue
    _ -> nil
  end

  defp get_duration(first, second) do
    diff_in_seconds =
      second
      |> Timex.diff(first)
      |> div(1_000_000)

    duration = Timex.Duration.from_seconds(diff_in_seconds)

    Timex.Format.Duration.Formatters.Humanized.format(duration)
  end
end
