defmodule ArtemisWeb.JobView do
  use ArtemisWeb, :view

  def data_table_available_columns() do
    [
      {"Actions", "actions"},
      {"Command", "command"},
      {"First Run", "first_run"},
      {"ID", "id"},
      {"Name", "name"},
      {"Status", "status"}
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
        value: fn _conn, row -> row.cmd end
      ],
      "first_run" => [
        label: fn _conn -> "First Run" end,
        value: fn _conn, row -> row.first_run end
      ],
      "id" => [
        label: fn _conn -> "ID" end,
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
        value: fn _conn, row -> row.name end
      ],
      "status" => [
        label: fn _conn -> "Status" end,
        value: &status_row_value/2,
        value_html: &status_row_value_html/2
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
