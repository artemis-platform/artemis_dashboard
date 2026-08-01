defmodule ArtemisWeb.DataTable do
  @moduledoc """
  Data table component with sortable columns, selectable rows, and
  configurable column display.

  Ported from the original `ArtemisWeb.ViewHelper.Tables` module.

  ## Usage

      <ArtemisWeb.DataTable.data_table
        id="users-table"
        rows={@users}
        allowed_columns={allowed_columns()}
        default_columns={["name", "email", "actions"]}
        sort_params={@query_params["order"]}
        request_path={@request_path}
        query_params={@query_params}
      />

  ## Allowed columns

  A map where each key is a URI-friendly slug and the value is a keyword
  list with `:label` and `:value` functions:

      %{
        "name" => [
          label: fn -> "Name" end,
          value: fn row -> row.name end,
          value_html: fn row ->
            assigns = %{row: row}
            ~H"<.link navigate={~p\"/users/\#{@row.id}\"}>{@row.name}</.link>"
          end
        ]
      }

  The table first looks for `value_html`, falling back to `value`.
  """
  use Phoenix.Component

  import ArtemisWeb.CoreComponents

  @default_delimiter ","

  @doc """
  Renders a data table from `allowed_columns` configuration.

  This is the primary component, matching the old `render_data_table/3`.
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :allowed_columns, :map, required: true
  attr :default_columns, :list, default: []
  attr :selectable, :boolean, default: false
  attr :compact, :boolean, default: false
  attr :headers, :boolean, default: true
  attr :sort_params, :string, default: nil
  attr :request_path, :string, default: nil
  attr :query_params, :map, default: %{}
  attr :class, :any, default: nil
  attr :empty_message, :string, default: "No records found"

  def data_table(assigns) do
    columns =
      resolve_columns(
        assigns.allowed_columns,
        assigns.default_columns,
        assigns.query_params,
        assigns.selectable
      )

    assigns = assign(assigns, :columns, columns)

    ~H"""
    <div class={[
      "overflow-x-auto rounded-lg border border-base-300",
      @compact && "data-table-compact",
      @class
    ]}>
      <table class="table table-sm w-full">
        <thead :if={@headers}>
          <tr class="bg-base-200/50 border-b border-base-300">
            <th
              :for={col <- @columns}
              class="text-xs font-semibold uppercase tracking-wider text-base-content/60 py-3 px-4"
            >
              <%= if col[:sortable] && @request_path do %>
                <.sort_link
                  field={col[:sort_key]}
                  label={render_column_label(col)}
                  sort_params={@sort_params}
                  request_path={@request_path}
                  query_params={@query_params}
                />
              <% else %>
                {render_column_label(col)}
              <% end %>
            </th>
          </tr>
        </thead>
        <tbody id={@id}>
          <%= if @rows == [] do %>
            <tr>
              <td colspan={length(@columns)} class="text-center py-8 text-base-content/50 text-sm">
                {@empty_message}
              </td>
            </tr>
          <% end %>
          <tr
            :for={row <- @rows}
            class="hover:bg-base-200/30 border-b border-base-300 last:border-b-0 transition-colors"
          >
            <td :for={col <- @columns} class="py-3 px-4 text-sm">
              {render_column_value(col, row)}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a sortable table header link.

  Matches the old `sortable_table_header/4`.
  """
  attr :field, :string, required: true
  attr :label, :string, required: true
  attr :sort_params, :string, default: nil
  attr :request_path, :string, required: true
  attr :query_params, :map, default: %{}

  def sort_link(assigns) do
    current_order = assigns.sort_params || ""
    fields = String.split(current_order, @default_delimiter, trim: true)

    {direction, new_order} = compute_sort(fields, assigns.field)

    updated_params = Map.put(assigns.query_params, "order", new_order)
    query_string = Plug.Conn.Query.encode(updated_params)
    path = "#{assigns.request_path}?#{query_string}"

    assigns =
      assigns
      |> assign(:path, path)
      |> assign(:direction, direction)

    ~H"""
    <.link
      navigate={@path}
      class="inline-flex items-center gap-1 hover:text-base-content transition-colors group"
    >
      {@label}
      <span class="text-base-content/30 group-hover:text-base-content/60">
        <.icon :if={@direction == :asc} name="hero-chevron-up" class="size-3" />
        <.icon :if={@direction == :desc} name="hero-chevron-down" class="size-3" />
        <.icon :if={@direction == nil} name="hero-chevron-up-down" class="size-3" />
      </span>
    </.link>
    """
  end

  @doc """
  Renders a column selector dropdown.

  Matches the old `render_data_table_column_selector/2`.
  """
  attr :available_columns, :list, required: true
  attr :selected_columns, :list, default: []
  attr :request_path, :string, required: true
  attr :query_params, :map, default: %{}
  attr :class, :any, default: nil

  def column_selector(assigns) do
    assigns =
      assign_new(assigns, :dropdown_id, fn ->
        "col-selector-#{System.unique_integer([:positive])}"
      end)

    ~H"""
    <div class={["dropdown dropdown-end", @class]}>
      <div
        tabindex="0"
        role="button"
        class={[
          "btn btn-sm btn-ghost gap-1",
          @selected_columns != [] && "btn-active"
        ]}
      >
        <.icon name="hero-view-columns" class="size-4" /> Columns
      </div>
      <ul
        tabindex="0"
        class="dropdown-content menu bg-base-100 rounded-box shadow-lg border border-base-300 w-56 p-2 z-50 max-h-80 overflow-y-auto"
      >
        <li :for={{label, key} <- @available_columns}>
          <a
            href={column_toggle_path(@request_path, @query_params, @selected_columns, key)}
            class={[Enum.member?(@selected_columns, key) && "active"]}
          >
            <.icon
              name={
                if(Enum.member?(@selected_columns, key),
                  do: "hero-check-circle-solid",
                  else: "hero-circle-stack"
                )
              }
              class="size-4"
            />
            {label}
          </a>
        </li>
      </ul>
    </div>
    """
  end

  # -------------------------------------------------------------------
  # Column resolution helpers
  # -------------------------------------------------------------------

  @doc """
  Resolves the active columns from allowed_columns, default_columns,
  and optional query params.
  """
  def resolve_columns(allowed_columns, default_columns, query_params, selectable \\ false) do
    requested =
      case Map.get(query_params || %{}, "columns") do
        nil -> default_columns
        val when is_binary(val) -> String.split(val, @default_delimiter, trim: true)
        val when is_list(val) -> val
      end

    columns =
      Enum.reduce(requested, [], fn key, acc ->
        case Map.get(allowed_columns, key) do
          nil -> acc
          col -> [Keyword.put(col, :key, key) | acc]
        end
      end)
      |> Enum.reverse()

    if selectable do
      [checkbox_column() | columns]
    else
      columns
    end
  end

  defp checkbox_column do
    [
      key: "_select",
      label: fn -> nil end,
      value: fn _row -> nil end
    ]
  end

  defp render_column_label(col) do
    label_fn = Keyword.get(col, :label_html, Keyword.fetch!(col, :label))
    label_fn.()
  end

  defp render_column_value(col, row) do
    value_fn = Keyword.get(col, :value_html, Keyword.fetch!(col, :value))
    value_fn.(row)
  end

  defp compute_sort(fields, field) do
    inverse = "-#{field}"

    cond do
      Enum.member?(fields, field) ->
        new_fields = replace_item(fields, field, inverse)
        {:asc, Enum.join(new_fields, @default_delimiter)}

      Enum.member?(fields, inverse) ->
        new_fields = replace_item(fields, inverse, field)
        {:desc, Enum.join(new_fields, @default_delimiter)}

      true ->
        {nil, field}
    end
  end

  defp replace_item(list, current, next) do
    case Enum.find_index(list, &(&1 == current)) do
      nil -> list
      index -> List.update_at(list, index, fn _ -> next end)
    end
  end

  defp column_toggle_path(request_path, query_params, selected, key) do
    updated =
      if Enum.member?(selected, key) do
        Enum.reject(selected, &(&1 == key))
      else
        selected ++ [key]
      end

    params = Map.put(query_params, "columns", Enum.join(updated, @default_delimiter))
    query_string = Plug.Conn.Query.encode(params)
    "#{request_path}?#{query_string}"
  end
end
