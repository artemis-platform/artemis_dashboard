defmodule ArtemisWeb.Export do
  @moduledoc """
  Export action components for data list pages.

  Ported from the original `ArtemisWeb.ViewHelper.Export`.

  ## Usage

      <ArtemisWeb.Export.export_actions
        request_path={@request_path}
        query_params={@query_params}
        available_columns={[{"Name", "name"}, {"Email", "email"}]}
      />
  """
  use Phoenix.Component

  import ArtemisWeb.CoreComponents

  @export_limit 100_000

  @doc """
  Returns the default export record limit.
  """
  def export_limit, do: @export_limit

  @doc """
  Renders an export dropdown with CSV download options.

  Matches the old `render_export_actions/2`.
  """
  attr :request_path, :string, required: true
  attr :query_params, :map, default: %{}
  attr :available_columns, :list, default: []
  attr :class, :any, default: nil

  def export_actions(assigns) do
    current_columns_path =
      build_export_path(assigns.request_path, assigns.query_params, %{
        "page_size" => @export_limit
      })

    all_columns =
      assigns.available_columns
      |> Enum.map(&elem(&1, 1))
      |> Enum.sort()

    all_columns_path =
      build_export_path(assigns.request_path, assigns.query_params, %{
        "page_size" => @export_limit,
        "columns" => all_columns
      })

    assigns =
      assigns
      |> assign(:current_columns_path, current_columns_path)
      |> assign(:all_columns_path, all_columns_path)

    ~H"""
    <div class={["dropdown dropdown-end", @class]}>
      <div tabindex="0" role="button" class="btn btn-sm btn-ghost gap-1">
        <.icon name="hero-arrow-down-tray" class="size-4" /> Export
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu bg-base-100 rounded-box shadow-lg border border-base-300 w-52 p-2 z-50"
      >
        <li>
          <a href={@current_columns_path} download class="text-sm">
            <.icon name="hero-table-cells" class="size-4" /> Current Columns
          </a>
        </li>
        <li :if={@available_columns != []}>
          <a href={@all_columns_path} download class="text-sm">
            <.icon name="hero-rectangle-stack" class="size-4" /> All Columns
          </a>
        </li>
      </ul>
    </div>
    """
  end

  # -------------------------------------------------------------------
  # Private helpers
  # -------------------------------------------------------------------

  defp build_export_path(request_path, query_params, extra_params) do
    merged =
      (query_params || %{})
      |> Map.put("_format", "csv")
      |> Map.merge(stringify_keys(extra_params))

    query_string = Plug.Conn.Query.encode(merged)
    "#{request_path}?#{query_string}"
  end

  defp stringify_keys(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end
end
