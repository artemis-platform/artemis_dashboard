defmodule ArtemisWeb.ViewHelper.BulkActions do
  use Phoenix.HTML

  defmodule BulkAction do
    defstruct [:action, :authorize, :extra_fields, :key, :label]
  end

  @doc """
  Render modal for bulk actions
  """
  def render_bulk_actions(conn, label, to, options \\ []) do
    allowed_bulk_actions = Keyword.get(options, :allowed_bulk_actions)
    extra_fields_data = Keyword.get(options, :extra_fields_data)
    color = Keyword.get(options, :color) || "basic"
    size = Keyword.get(options, :size, "medium")
    modal_id = "modal-id-#{Artemis.Helpers.UUID.call()}"

    button_options =
      []
      |> Keyword.put(:class, "button ui #{size} #{color} modal-trigger bulk-actions-button")
      |> Keyword.put(:data, target: "##{modal_id}")
      |> Keyword.put(:to, "#bulk-actions")

    current_path = "#{conn.request_path}?#{conn.query_string}"
    return_path = Keyword.get(options, :return_path, current_path)

    assigns = [
      allowed_bulk_actions: allowed_bulk_actions,
      button_label: label,
      button_options: button_options,
      extra_fields_data: extra_fields_data,
      modal_id: modal_id,
      return_path: return_path,
      to: to
    ]

    case length(allowed_bulk_actions) > 0 do
      true -> Phoenix.View.render(ArtemisWeb.LayoutView, "bulk_actions.html", assigns)
      false -> nil
    end
  end

  @doc """
  Render a reusable warning for bulk delete actions
  """
  def render_extra_fields_delete_warning(_extra_fields_data) do
    ArtemisWeb.ViewHelper.Notifications.render_notification(
      :error,
      header: "Warning",
      body: "The selected action will bulk delete multiple records. Proceed with caution!"
    )
  end
end
