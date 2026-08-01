defmodule ArtemisWeb.Pagination do
  @moduledoc """
  Pagination component for navigating paged result sets.

  Ported from the original `ArtemisWeb.ViewHelper.Pagination`.

  ## Usage

      <ArtemisWeb.Pagination.pagination
        total_pages={@total_pages}
        current_page={@current_page}
        request_path={@request_path}
        query_params={@query_params}
      />
  """
  use Phoenix.Component

  import ArtemisWeb.CoreComponents

  @doc """
  Renders page navigation controls.

  Supports standard numbered pagination and bookmark-based next/prev.
  """
  attr :total_pages, :integer, required: true
  attr :current_page, :integer, default: 1
  attr :request_path, :string, required: true
  attr :query_params, :map, default: %{}
  attr :class, :any, default: nil

  def pagination(assigns) do
    assigns =
      assigns
      |> assign(:pages, build_page_list(assigns.current_page, assigns.total_pages))

    ~H"""
    <nav
      :if={@total_pages > 1}
      class={["flex items-center justify-center gap-1", @class]}
      aria-label="Pagination"
    >
      <.page_link
        page={@current_page - 1}
        disabled={@current_page <= 1}
        request_path={@request_path}
        query_params={@query_params}
        aria_label="Previous page"
      >
        <.icon name="hero-chevron-left" class="size-4" />
      </.page_link>

      <%= for item <- @pages do %>
        <%= case item do %>
          <% :ellipsis -> %>
            <span class="px-2 text-base-content/40 text-sm select-none">&hellip;</span>
          <% page -> %>
            <.page_link
              page={page}
              active={page == @current_page}
              request_path={@request_path}
              query_params={@query_params}
            >
              {page}
            </.page_link>
        <% end %>
      <% end %>

      <.page_link
        page={@current_page + 1}
        disabled={@current_page >= @total_pages}
        request_path={@request_path}
        query_params={@query_params}
        aria_label="Next page"
      >
        <.icon name="hero-chevron-right" class="size-4" />
      </.page_link>
    </nav>
    """
  end

  @doc """
  Renders bookmark-based "Previous / Next" pagination.
  """
  attr :has_next, :boolean, default: false
  attr :has_previous, :boolean, default: false
  attr :next_bookmark, :string, default: nil
  attr :request_path, :string, required: true
  attr :query_params, :map, default: %{}
  attr :class, :any, default: nil

  def bookmark_pagination(assigns) do
    ~H"""
    <nav
      :if={@has_next || @has_previous}
      class={["flex items-center justify-between", @class]}
      aria-label="Pagination"
    >
      <div>
        <.link
          :if={@has_previous}
          navigate={page_path(@request_path, Map.delete(@query_params, "bookmark"))}
          class="btn btn-sm btn-ghost gap-1"
        >
          <.icon name="hero-arrow-uturn-left" class="size-4" /> First Page
        </.link>
      </div>
      <div>
        <.link
          :if={@has_next}
          navigate={page_path(@request_path, Map.put(@query_params, "bookmark", @next_bookmark))}
          class="btn btn-sm btn-ghost gap-1"
        >
          Next Page <.icon name="hero-chevron-right" class="size-4" />
        </.link>
      </div>
    </nav>
    """
  end

  # -------------------------------------------------------------------
  # Private
  # -------------------------------------------------------------------

  attr :page, :integer, required: true
  attr :active, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :request_path, :string, required: true
  attr :query_params, :map, default: %{}
  attr :aria_label, :string, default: nil

  slot :inner_block, required: true

  defp page_link(assigns) do
    path = page_path(assigns.request_path, Map.put(assigns.query_params, "page", assigns.page))
    assigns = assign(assigns, :path, path)

    ~H"""
    <span :if={@disabled} class="btn btn-sm btn-ghost btn-disabled opacity-40" aria-disabled="true">
      {render_slot(@inner_block)}
    </span>
    <.link
      :if={!@disabled}
      navigate={@path}
      class={[
        "btn btn-sm",
        if(@active, do: "btn-primary", else: "btn-ghost")
      ]}
      aria-label={@aria_label}
      aria-current={@active && "page"}
    >
      {render_slot(@inner_block)}
    </.link>
    """
  end

  defp page_path(request_path, params) do
    query_string = Plug.Conn.Query.encode(params)
    "#{request_path}?#{query_string}"
  end

  defp build_page_list(_current, total) when total <= 7, do: Enum.to_list(1..total)

  defp build_page_list(current, total) do
    cond do
      current <= 3 ->
        Enum.to_list(1..4) ++ [:ellipsis, total]

      current >= total - 2 ->
        [1, :ellipsis] ++ Enum.to_list((total - 3)..total)

      true ->
        [1, :ellipsis, current - 1, current, current + 1, :ellipsis, total]
    end
  end
end
