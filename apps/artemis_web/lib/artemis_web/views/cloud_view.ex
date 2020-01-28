defmodule ArtemisWeb.CloudView do
  use ArtemisWeb, :view

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.UpdateCloud.call_many(&1, &2),
        authorize: &has?(&1, "clouds:update"),
        extra_fields: &render_extra_field_select_customer/1,
        key: "update_customer",
        label: "Update Customer"
      },
      %BulkAction{
        action: &Artemis.DeleteCloud.call_many(&1, &2),
        authorize: &has?(&1, "clouds:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Clouds"
      }
    ]
  end

  defp render_extra_field_select_customer(data) do
    customers = Keyword.get(data, :customers)
    label = content_tag(:label, "Customer")
    select = select_tag(customers, name: "customer_id", placeholder: "Customer")

    content_tag(:div, class: "field") do
      [label, select]
    end
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
      {"Customer", "customer"},
      {"Data Centers", "data_centers"},
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
      "customer" => [
        label: fn _conn -> "Customer" end,
        value: fn _conn, row -> Artemis.Helpers.deep_get(row, [:customer, :name]) end,
        value_html: fn conn, row ->
          if row.customer do
            ArtemisWeb.CustomerView.render_show_link(conn, row.customer)
          end
        end
      ],
      "data_center_count" => [
        label: fn _conn -> "Data Center Count" end,
        value: fn _conn, row -> length(row.data_centers) end
      ],
      "data_centers" => [
        label: fn _conn -> "Data Centers" end,
        value: fn _conn, row ->
          Enum.map(row.data_centers, fn entry ->
            Artemis.Helpers.deep_get(entry, [:data_center, :name])
          end)
        end,
        value_html: fn conn, row ->
          row
          |> Map.get(:data_centers)
          |> Enum.sort_by(& &1.name)
          |> Enum.map(fn entry ->
            content_tag(:div) do
              ArtemisWeb.DataCenterView.render_show_link(conn, entry)
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
        label: fn _conn -> "Cloud Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "name", "Cloud Name")
        end,
        value: fn _conn, row -> row.name end,
        value_html: fn conn, row ->
          case has?(conn, "clouds:show") do
            true -> link(row.name, to: Routes.cloud_path(conn, :show, row))
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
        verify: has?(conn, "clouds:show"),
        link: link("Show", to: Routes.cloud_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "clouds:update"),
        link: link("Edit", to: Routes.cloud_path(conn, :edit, row))
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
    link(record.name, to: Routes.cloud_path(conn, :show, record))
  end
end
