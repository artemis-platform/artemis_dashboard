defmodule ArtemisWeb.Breadcrumbs do
  @moduledoc """
  Breadcrumb navigation component.

  Renders a flat breadcrumb trail with a home icon, `/` separators,
  and the current page highlighted.

  ## Usage

      <ArtemisWeb.Breadcrumbs.breadcrumbs uri="/clouds/123" />

  Or with explicit items:

      <ArtemisWeb.Breadcrumbs.breadcrumbs>
        <:item href="/clouds">Clouds</:item>
        <:item>Cloud 123</:item>
      </ArtemisWeb.Breadcrumbs.breadcrumbs>
  """
  use Phoenix.Component

  @doc """
  Renders breadcrumb navigation from a request path or explicit items.
  """
  attr :uri, :string, default: nil
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

        assigns.uri ->
          build_from_uri(assigns.uri)

        true ->
          []
      end

    assigns = assign(assigns, :items, items)

    ~H"""
    <nav :if={@items != []} class={["text-sm", @class]} aria-label="Breadcrumbs">
      <ol class="flex items-center text-[13px] text-base-content/50 gap-2">
        <li class="flex items-center">
          <.link href="/" class="-mt-0.5 text-base-content/40 hover:text-base-content/70 transition-colors">
            <ArtemisWeb.CoreComponents.icon name="hero-home-solid" class="size-4" />
          </.link>
        </li>
        <li :for={{item, index} <- Enum.with_index(@items)} class="flex items-center gap-2">
          <span class="text-base-content/30">/</span>
          <%= if item.href && index < length(@items) - 1 do %>
            <.link
              navigate={item.href}
              class="text-base-content/50 hover:text-base-content/70 transition-colors"
            >
              <%= if item.slot do %>
                {render_slot(item.slot)}
              <% else %>
                {item.label}
              <% end %>
            </.link>
          <% else %>
            <span class="text-base-content/70 font-medium">
              <%= if item.slot do %>
                {render_slot(item.slot)}
              <% else %>
                {item.label}
              <% end %>
            </span>
          <% end %>
        </li>
      </ol>
    </nav>
    """
  end

  defp build_from_uri(uri) do
    path =
      uri
      |> URI.parse()
      |> Map.get(:path)

    sections = String.split(path, "/", trim: true)

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
