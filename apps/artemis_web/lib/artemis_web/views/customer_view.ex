defmodule ArtemisWeb.CustomerView do
  use ArtemisWeb, :view

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.DeleteCustomer.call_many(&1, &2),
        authorize: &has?(&1, "customers:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Customers"
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
      {"Customer", "customer"},
      {"Cloud Count", "cloud_count"},
      {"Clouds", "clouds"},
      {"Data Center Count", "data_center_count"},
      {"Data Centers", "data_centers"},
      {"Machine Count", "machine_count"},
      {"Machines", "machines"},
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
          case has?(conn, "customers:show") do
            true -> link(row.name, to: Routes.customer_path(conn, :show, row))
            false -> row.name
          end
        end
      ]
    }
  end

  defp data_table_actions_column_html(conn, row) do
    allowed_actions = [
      [
        verify: has?(conn, "customers:show"),
        link: link("Show", to: Routes.customer_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "customers:update"),
        link: link("Edit", to: Routes.customer_path(conn, :edit, row))
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
    link(record.name, to: Routes.customer_path(conn, :show, record))
  end
end
