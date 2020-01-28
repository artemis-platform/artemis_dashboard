defmodule ArtemisWeb.DataCenterView do
  use ArtemisWeb, :view

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.DeleteDataCenter.call_many(&1, &2),
        authorize: &has?(&1, "data-centers:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Data Centers"
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
      {"Clouds", "clouds"},
      {"Customers", "customers"},
      {"Machine Count", "machine_count"},
      {"Machine Total CPU", "machine_total_cpu"},
      {"Machine Total RAM", "machine_total_ram"},
      {"Machines", "machines"},
      {"Name", "name"},
      {"Slug", "slug"}
    ]
  end

  def data_table_allowed_columns() do
    %{
      "actions" => [
        label: fn _conn -> nil end,
        value: fn _conn, _row -> nil end,
        value_html: &data_table_actions_column_html/2
      ],
      "cloud_count" => [
        label: fn _conn -> "Cloud Count" end,
        value: fn _conn, row -> length(row.clouds) end
      ],
      "clouds" => [
        label: fn _conn -> "Clouds" end,
        value: fn _conn, row ->
          Enum.map(row.clouds, fn entry ->
            Artemis.Helpers.deep_get(entry, [:cloud, :name])
          end)
        end,
        value_html: fn conn, row ->
          row
          |> Map.get(:clouds)
          |> Enum.sort_by(& &1.name)
          |> Enum.map(fn entry ->
            content_tag(:div) do
              ArtemisWeb.CloudView.render_show_link(conn, entry)
            end
          end)
        end
      ],
      "customer_count" => [
        label: fn _conn -> "Customer Count" end,
        value: fn _conn, row -> length(row.customers) end
      ],
      "customers" => [
        label: fn _conn -> "Customers" end,
        value: fn _conn, row ->
          Enum.map(row.customers, fn entry ->
            Artemis.Helpers.deep_get(entry, [:customer, :name])
          end)
        end,
        value_html: fn conn, row ->
          Enum.map(row.customers, fn entry ->
            content_tag(:div) do
              ArtemisWeb.CustomerView.render_show_link(conn, entry)
            end
          end)
        end
      ],
      "machine_count" => [
        label: fn _conn -> "Machine Count" end,
        value: fn _conn, row -> length(row.machines) end
      ],
      "machine_total_cpu" => [
        label: fn _conn -> "CPU" end,
        value: fn _conn, row -> sum(row.machines, :cpu_total) end,
        value_html: fn _conn, row -> "#{sum(row.machines, :cpu_total)} CPU" end
      ],
      "machine_total_ram" => [
        label: fn _conn -> "RAM" end,
        value: fn _conn, row -> sum(row.machines, :ram_total) end,
        value_html: fn _conn, row -> "#{sum(row.machines, :ram_total)} GB" end
      ],
      "machines" => [
        label: fn _conn -> "Machines" end,
        value: fn _conn, row ->
          Enum.map(row.machines, fn entry ->
            Artemis.Helpers.deep_get(entry, [:machine, :name])
          end)
        end,
        value_html: fn conn, row ->
          row
          |> Map.get(:machines)
          |> Enum.sort_by(& &1.name)
          |> Enum.map(fn entry ->
            content_tag(:div) do
              ArtemisWeb.MachineView.render_show_link(conn, entry)
            end
          end)
        end
      ],
      "name" => [
        label: fn _conn -> "Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "name", "Name")
        end,
        value: fn _conn, row -> row.name end,
        value_html: fn conn, row ->
          case has?(conn, "data-centers:show") do
            true -> link(row.name, to: Routes.data_center_path(conn, :show, row))
            false -> row.name
          end
        end
      ],
      "slug" => [
        label: fn _conn -> "Slug" end,
        label_html: fn conn ->
          sortable_table_header(conn, "slug", "Slug")
        end,
        value: fn _conn, row -> row.slug end,
        value_html: fn _conn, row ->
          content_tag(:code, row.slug)
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "data-centers:show"),
        link: link("Show", to: Routes.data_center_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "data-centers:update"),
        link: link("Edit", to: Routes.data_center_path(conn, :edit, row))
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

  defp sum(data, key), do: Enum.reduce(data, 0, &(&2 + Map.get(&1, key)))

  # Helpers

  def render_show_link(_conn, nil), do: nil

  def render_show_link(conn, record) do
    link(record.name, to: Routes.data_center_path(conn, :show, record))
  end
end
