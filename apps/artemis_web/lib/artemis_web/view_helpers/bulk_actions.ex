defmodule ArtemisWeb.ViewHelper.BulkActions do
  use Phoenix.HTML

  defmodule BulkAction do
    defstruct [:action, :authorize, :extra_fields, :key, :label]
  end

  @doc """
  Render modal for bulk actions
  """
  def render_bulk_actions(label, to, options \\ []) do
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

    assigns = [
      allowed_bulk_actions: allowed_bulk_actions,
      extra_fields_data: extra_fields_data,
      button_label: label,
      button_options: button_options,
      modal_id: modal_id,
      to: to
    ]

    Phoenix.View.render(ArtemisWeb.LayoutView, "bulk_actions.html", assigns)
  end
end
