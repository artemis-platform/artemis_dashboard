defmodule ArtemisWeb.Filter do
  @moduledoc """
  Filter components for data list pages.

  Ported from the original `ArtemisWeb.ViewHelper.Filter`.

  ## Usage

      <ArtemisWeb.Filter.page_filters>
        <ArtemisWeb.Filter.filter_button
          label="Active"
          values={[status: "active"]}
          query_params={@query_params}
          request_path={@request_path}
        />
      </ArtemisWeb.Filter.page_filters>
  """
  use Phoenix.Component

  import ArtemisWeb.CoreComponents

  @doc """
  Renders a filter container with a heading and filter controls.

  Matches the old `page_filters/1`.
  """
  attr :label, :string, default: "Data Filters"
  attr :class, :any, default: nil

  slot :inner_block, required: true

  def page_filters(assigns) do
    ~H"""
    <div class={["flex flex-wrap items-center gap-3 py-3", @class]}>
      <span class="text-sm font-medium text-base-content/60 flex items-center gap-1.5">
        <.icon name="hero-funnel" class="size-4" />
        {@label}
      </span>
      <div class="flex flex-wrap items-center gap-2">
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc """
  Renders a filter button that toggles a query param under the `filters` key.

  Matches the old `filter_button/4`.
  """
  attr :label, :string, required: true
  attr :values, :list, required: true
  attr :query_params, :map, default: %{}
  attr :request_path, :string, required: true
  attr :class, :any, default: nil

  def filter_button(assigns) do
    filter_data = compute_filter(assigns.query_params, assigns.request_path, assigns.values)
    assigns = assign(assigns, :filter_data, filter_data)

    ~H"""
    <.link
      navigate={@filter_data.path}
      class={[
        "btn btn-sm",
        if(@filter_data.active?, do: "btn-primary", else: "btn-ghost border border-base-300"),
        @class
      ]}
    >
      {@label}
    </.link>
    """
  end

  @doc """
  Renders a filter toggle (checkbox style).

  Matches the old `filter_toggle/4`.
  """
  attr :label, :string, required: true
  attr :key, :string, required: true
  attr :value, :string, required: true
  attr :query_params, :map, default: %{}
  attr :request_path, :string, required: true

  def filter_toggle(assigns) do
    current_filters = Map.get(assigns.query_params, "filters", %{})
    active = Map.get(current_filters, assigns.key) == assigns.value

    toggled_value = if active, do: nil, else: assigns.value
    updated_filters = Map.put(current_filters, assigns.key, toggled_value)
    updated_params = Map.put(assigns.query_params, "filters", updated_filters)
    query_string = Plug.Conn.Query.encode(updated_params)
    path = "#{assigns.request_path}?#{query_string}"

    assigns =
      assigns
      |> assign(:active, active)
      |> assign(:path, path)
      |> assign(:toggle_id, "filter-toggle-#{System.unique_integer([:positive])}")

    ~H"""
    <.link navigate={@path} class="flex items-center gap-2 cursor-pointer">
      <input
        type="checkbox"
        checked={@active}
        class="toggle toggle-sm toggle-primary"
        id={@toggle_id}
        tabindex="-1"
      />
      <label for={@toggle_id} class="text-sm cursor-pointer">{@label}</label>
    </.link>
    """
  end

  @doc """
  Renders a text input filter field.

  Matches the old `filter_input_field/3`.
  """
  attr :label, :string, required: true
  attr :key, :string, required: true
  attr :query_params, :map, default: %{}
  attr :request_path, :string, required: true
  attr :class, :any, default: nil

  def filter_input(assigns) do
    current_filters = Map.get(assigns.query_params, "filters", %{})
    current_value = Map.get(current_filters, assigns.key, "")

    assigns = assign(assigns, :current_value, current_value || "")

    ~H"""
    <form method="get" action={@request_path} class={["inline-flex items-center gap-2", @class]}>
      <%= for {key, value} <- @query_params, key != "filters" do %>
        <input type="hidden" name={key} value={value} />
      <% end %>

      <label class="text-sm text-base-content/70">{@label}</label>
      <input
        type="text"
        name={"filters[#{@key}]"}
        value={@current_value}
        class="input input-sm input-bordered w-40"
        placeholder={@label}
      />
    </form>
    """
  end

  @doc """
  Renders a select dropdown filter.

  Matches the old `filter_select/5`.
  """
  attr :label, :string, required: true
  attr :key, :string, required: true
  attr :options, :list, required: true
  attr :query_params, :map, default: %{}
  attr :request_path, :string, required: true
  attr :class, :any, default: nil

  def filter_select(assigns) do
    current_filters = Map.get(assigns.query_params, "filters", %{})
    current_value = Map.get(current_filters, assigns.key, "")

    assigns = assign(assigns, :current_value, current_value || "")

    ~H"""
    <form method="get" action={@request_path} class={["inline-flex items-center gap-2", @class]}>
      <%= for {key, value} <- @query_params, key != "filters" do %>
        <input type="hidden" name={key} value={value} />
      <% end %>

      <label class="text-sm text-base-content/70">{@label}</label>
      <select
        name={"filters[#{@key}]"}
        class="select select-sm select-bordered"
        onchange="this.form.submit()"
      >
        <option value="">All</option>
        {Phoenix.HTML.Form.options_for_select(@options, @current_value)}
      </select>
    </form>
    """
  end

  @doc """
  Renders a multi-select filter with checkboxes.

  Matches the old `filter_multi_select/5`.
  """
  attr :label, :string, required: true
  attr :key, :string, required: true
  attr :options, :list, required: true
  attr :query_params, :map, default: %{}
  attr :request_path, :string, required: true
  attr :class, :any, default: nil

  def filter_multi_select(assigns) do
    current_filters = Map.get(assigns.query_params, "filters", %{})
    selected = Map.get(current_filters, assigns.key, [])
    selected = if is_list(selected), do: selected, else: [selected]
    active = selected != []

    assigns =
      assigns
      |> assign(:selected, selected)
      |> assign(:active, active)
      |> assign(:dropdown_id, "filter-ms-#{System.unique_integer([:positive])}")

    ~H"""
    <div class={["dropdown", @class]}>
      <div
        tabindex="0"
        role="button"
        class={[
          "btn btn-sm gap-1",
          if(@active, do: "btn-primary", else: "btn-ghost border border-base-300")
        ]}
      >
        <.icon name="hero-funnel" class="size-3.5" />
        {@label}
        <span :if={@active} class="badge badge-sm badge-primary-content">{length(@selected)}</span>
      </div>
      <div
        tabindex="0"
        class="dropdown-content bg-base-100 rounded-box shadow-lg border border-base-300 w-56 p-3 z-50"
      >
        <form method="get" action={@request_path}>
          <%= for {key, value} <- @query_params, key != "filters" do %>
            <input type="hidden" name={key} value={value} />
          <% end %>

          <div class="space-y-2 max-h-60 overflow-y-auto">
            <label
              :for={{option_label, option_value} <- @options}
              class="flex items-center gap-2 cursor-pointer text-sm"
            >
              <input
                type="checkbox"
                name={"filters[#{@key}][]"}
                value={option_value}
                checked={Enum.member?(@selected, to_string(option_value))}
                class="checkbox checkbox-sm checkbox-primary"
              />
              {option_label}
            </label>
          </div>
          <div class="mt-3 pt-2 border-t border-base-300">
            <button type="submit" class="btn btn-sm btn-primary w-full">Apply</button>
          </div>
        </form>
      </div>
    </div>
    """
  end

  # -------------------------------------------------------------------
  # Private helpers
  # -------------------------------------------------------------------

  defp compute_filter(query_params, request_path, values) do
    current_filters = Map.get(query_params, "filters", %{})

    new_filter_entries =
      values
      |> Enum.map(fn {k, v} -> {to_string(k), v} end)
      |> Enum.into(%{})

    active? =
      Enum.all?(new_filter_entries, fn {k, v} ->
        Map.get(current_filters, k) == v
      end)

    updated_filters =
      if active? do
        Enum.reduce(new_filter_entries, current_filters, fn {k, _v}, acc ->
          Map.delete(acc, k)
        end)
      else
        Map.merge(current_filters, new_filter_entries)
      end

    updated_params = Map.put(query_params, "filters", updated_filters)
    query_string = Plug.Conn.Query.encode(updated_params)
    path = "#{request_path}?#{query_string}"

    %{active?: active?, path: path}
  end
end
