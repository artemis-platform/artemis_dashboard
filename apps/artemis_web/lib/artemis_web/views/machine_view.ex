defmodule ArtemisWeb.MachineView do
  use ArtemisWeb, :view

  # Bulk Actions

  def available_bulk_actions() do
    [
      %BulkAction{
        action: &Artemis.UpdateMachine.call_many(&1, &2),
        authorize: &has?(&1, "machines:update"),
        extra_fields: &render_extra_field_select_cloud/1,
        key: "update_cloud",
        label: "Update Cloud"
      },
      %BulkAction{
        action: &Artemis.UpdateMachine.call_many(&1, &2),
        authorize: &has?(&1, "machines:update"),
        extra_fields: &render_extra_field_select_data_center/1,
        key: "update_data_center",
        label: "Update Data Center"
      },
      %BulkAction{
        action: &Artemis.DeleteMachine.call_many(&1, &2),
        authorize: &has?(&1, "machines:delete"),
        extra_fields: &render_extra_fields_delete_warning(&1),
        key: "delete",
        label: "Delete Machines"
      }
    ]
  end

  defp render_extra_field_select_cloud(data) do
    clouds = Keyword.get(data, :clouds)
    label = content_tag(:label, "Cloud")
    select = select_tag(clouds, name: "cloud_id", placeholder: "Cloud")

    content_tag(:div, class: "field") do
      [label, select]
    end
  end

  defp render_extra_field_select_data_center(data) do
    data_centers = Keyword.get(data, :data_centers)
    label = content_tag(:label, "Data Center")
    select = select_tag(data_centers, name: "data_center_id", placeholder: "Data Center")

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
      {"Cloud", "cloud"},
      {"Customer", "customer"},
      {"Data Center", "data_center"},
      {"Hostname", "hostname"},
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
      "cloud" => [
        label: fn _conn -> "Cloud" end,
        value: fn _conn, row -> Artemis.Helpers.deep_get(row, [:cloud, :name]) end,
        value_html: fn conn, row ->
          if row.cloud do
            ArtemisWeb.CloudView.render_show_link(conn, row.cloud)
          end
        end
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
      "data_center" => [
        label: fn _conn -> "Data Center" end,
        value: fn _conn, row -> Artemis.Helpers.deep_get(row, [:data_center, :name]) end,
        value_html: fn conn, row ->
          if row.data_center do
            ArtemisWeb.DataCenterView.render_show_link(conn, row.data_center)
          end
        end
      ],
      "hostname" => [
        label: fn _conn -> "Hostname" end,
        label_html: fn conn ->
          sortable_table_header(conn, "hostname", "Hostname")
        end,
        value: fn _conn, row -> row.hostname end,
        value_html: fn _conn, row ->
          content_tag(:code, row.hostname)
        end
      ],
      "name" => [
        label: fn _conn -> "Name" end,
        label_html: fn conn ->
          sortable_table_header(conn, "name", "Name")
        end,
        value: fn _conn, row -> row.name end,
        value_html: fn conn, row ->
          case has?(conn, "machines:show") do
            true -> link(row.name, to: Routes.machine_path(conn, :show, row))
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
        verify: has?(conn, "machines:show"),
        link: link("Show", to: Routes.machine_path(conn, :show, row))
      ],
      [
        verify: has?(conn, "machines:update"),
        link: link("Edit", to: Routes.machine_path(conn, :edit, row))
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
    link(record.name, to: Routes.machine_path(conn, :show, record))
  end
end
