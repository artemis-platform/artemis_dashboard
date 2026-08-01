defmodule ArtemisWeb.Search do
  @moduledoc """
  Search bar component for resource list pages.

  Ported from the original `ArtemisWeb.ViewHelper.Search`.

  ## Usage

      <ArtemisWeb.Search.search_bar
        query_params={@query_params}
        request_path={@request_path}
      />
  """
  use Phoenix.Component

  import ArtemisWeb.CoreComponents

  @doc """
  Renders a search input with optional clear button.
  """
  attr :query_params, :map, default: %{}
  attr :request_path, :string, required: true
  attr :placeholder, :string, default: "Search..."
  attr :param_key, :string, default: "query"
  attr :class, :any, default: nil

  def search_bar(assigns) do
    current_query = Map.get(assigns.query_params, assigns.param_key, "")
    active = current_query != "" && current_query != nil

    clear_params = Map.delete(assigns.query_params, assigns.param_key)
    clear_query_string = Plug.Conn.Query.encode(clear_params)
    clear_path = "#{assigns.request_path}?#{clear_query_string}"

    assigns =
      assigns
      |> assign(:current_query, current_query || "")
      |> assign(:active, active)
      |> assign(:clear_path, clear_path)

    ~H"""
    <form method="get" action={@request_path} class={["relative", @class]}>
      <%= for {key, value} <- @query_params, key != @param_key do %>
        <input type="hidden" name={key} value={value} />
      <% end %>

      <div class="relative">
        <.icon
          name="hero-magnifying-glass"
          class="absolute left-3 top-1/2 -translate-y-1/2 size-4 text-base-content/40"
        />
        <input
          type="search"
          name={@param_key}
          value={@current_query}
          placeholder={@placeholder}
          class={[
            "w-full pl-9 pr-9 py-2 text-sm bg-base-100 border rounded-lg",
            "focus:outline-none focus:ring-1 focus:ring-primary focus:border-primary transition-colors",
            if(@active, do: "border-primary", else: "border-base-300")
          ]}
        />
        <.link
          :if={@active}
          navigate={@clear_path}
          class="absolute right-2 top-1/2 -translate-y-1/2 p-0.5 text-base-content/40 hover:text-base-content/70 transition-colors"
          aria-label="Clear search"
        >
          <.icon name="hero-x-circle-solid" class="size-4" />
        </.link>
      </div>
    </form>
    """
  end
end
