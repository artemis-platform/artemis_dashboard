defmodule ArtemisWeb.Breadcrumbs do
  @moduledoc """
  Breadcrumb navigation component.

  Ported from the original `ArtemisWeb.ViewHelper.Breadcrumbs`.

  ## Usage

      <ArtemisWeb.Breadcrumbs.breadcrumbs request_path="/clouds/123" />

  Or with explicit items:

      <ArtemisWeb.Breadcrumbs.breadcrumbs>
        <:item href="/">Home</:item>
        <:item href="/clouds">Clouds</:item>
        <:item>Cloud 123</:item>
      </ArtemisWeb.Breadcrumbs.breadcrumbs>
  """
  use Phoenix.Component

  @doc """
  Renders breadcrumb navigation from a request path or explicit items.
  """
  attr :request_path, :string, default: nil
  attr :class, :any, default: nil

  slot :item do
    attr :href, :string
  end

  def breadcrumbs(assigns) do
    items =
      cond do
        assigns.item != [] ->
          Enum.map(assigns.item, fn slot ->
            %{href: slot[:href], label: nil, slot: slot}
          end)

        assigns.request_path ->
          build_from_path(assigns.request_path)

        true ->
          []
      end

    assigns = assign(assigns, :items, items)

    ~H"""
    <nav :if={@items != []} class={["text-sm breadcrumbs py-0", @class]} aria-label="Breadcrumbs">
      <ul>
        <li :for={{item, index} <- Enum.with_index(@items)}>
          <%= if item.href && index < length(@items) - 1 do %>
            <.link
              navigate={item.href}
              class="text-base-content/50 hover:text-base-content transition-colors"
            >
              <%= if item.slot do %>
                {render_slot(item.slot)}
              <% else %>
                {item.label}
              <% end %>
            </.link>
          <% else %>
            <span class="text-base-content/70">
              <%= if item.slot do %>
                {render_slot(item.slot)}
              <% else %>
                {item.label}
              <% end %>
            </span>
          <% end %>
        </li>
      </ul>
    </nav>
    """
  end

  # -------------------------------------------------------------------
  # Private helpers
  # -------------------------------------------------------------------

  defp build_from_path(path) do
    sections = String.split(path, "/", trim: true)
    root = %{href: "/", label: "Home", slot: nil}

    crumbs =
      sections
      |> Enum.with_index()
      |> Enum.map(fn {section, index} ->
        href =
          sections
          |> Enum.take(index + 1)
          |> Enum.join("/")

        %{
          href: "/#{href}",
          label: pretty_print(section),
          slot: nil
        }
      end)

    [root | crumbs]
  end

  defp pretty_print(value) do
    value
    |> String.replace("-", " ")
    |> String.replace("_", " ")
    |> titlecase()
  end

  defp titlecase(str) do
    str
    |> String.split(" ")
    |> Enum.map_join(" ", fn word ->
      case String.downcase(word) do
        <<first::utf8, rest::binary>> -> String.upcase(<<first::utf8>>) <> rest
        other -> other
      end
    end)
  end
end
