defmodule ArtemisWeb.ViewHelper.HTML do
  use Phoenix.HTML

  import Phoenix.HTML.Tag

  @doc """
  Generates an action tag.

  Type of tag is determined by the `method`:

    GET: Anchor
    POST / PUT / PATCH / DELETE: Button (with CSRF token)

  Unless specified, the `method` value defaults to `GET`.

  Custom options:

    :color <String>
    :size <String>

  All other options are passed directly to the `Phoenix.HTML` function.
  """
  def action(label, options \\ []) do
    color = Keyword.get(options, :color, "basic")
    size = Keyword.get(options, :size, "small")
    method = Keyword.get(options, :method, "get")
    live? = Keyword.get(options, :live, false)

    tag_options =
      options
      |> Enum.into(%{})
      |> Map.put(:class, "button ui #{size} #{color}")
      |> Enum.into([])

    cond do
      method == "get" && live? -> Phoenix.LiveView.live_link(label, tag_options)
      method == "get" -> link(label, tag_options)
      true -> button(label, tag_options)
    end
  end

  @doc """
  Reload button
  """
  def render_reload_action(options \\ []) do
    default_options = [
      label: "Refresh",
      onclick: "javascript:window.location.reload()",
      size: "small",
      to: "#action-reloading-page"
    ]

    options = Keyword.merge(default_options, options)
    label = Keyword.get(options, :label)

    action(label, options)
  end

  @doc """
  """
  def delete_confirmation(label, to, options \\ []) do
    color = Keyword.get(options, :color) || "basic"
    size = Keyword.get(options, :size, "small")

    button_options =
      options
      |> Keyword.delete(:to)
      |> Keyword.put(:class, "button ui confirmation #{size} #{color}")
      |> Keyword.put(:to, "#delete-confirmation")

    assigns = [
      button_label: label,
      button_options: button_options,
      to: to
    ]

    Phoenix.View.render(ArtemisWeb.LayoutView, "delete_confirmation.html", assigns)
  end

  @doc """
  Render a H2 tag
  """
  def h2(label, options \\ []) do
    slug = Artemis.Helpers.generate_slug(label)
    id = "link-#{slug}"

    content_tag(:div, class: "heading-container h2-container", id: id) do
      content_tag(:h2, label, options)
    end
  end

  @doc """
  Render a H3 tag
  """
  def h3(label, options \\ []) do
    slug = Artemis.Helpers.generate_slug(label)
    id = "link-#{slug}"

    content_tag(:div, class: "heading-container h3-container", id: id) do
      content_tag(:h3, label, options)
    end
  end

  @doc """
  Render a H4 tag
  """
  def h4(label, options \\ []) do
    slug = Artemis.Helpers.generate_slug(label)
    id = "link-#{slug}"

    content_tag(:div, class: "heading-container h4-container", id: id) do
      content_tag(:h4, label, options)
    end
  end

  @doc """
  Render a H5 tag
  """
  def h5(label, options \\ []) do
    slug = Artemis.Helpers.generate_slug(label)
    id = "link-#{slug}"

    content_tag(:div, class: "heading-container h5-container", id: id) do
      content_tag(:h5, label, options)
    end
  end
end
