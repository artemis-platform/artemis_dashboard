defmodule ArtemisWeb.ViewHelper.Status do
  use Phoenix.HTML

  @status_color_lookup %{
    # Color - Red
    "red" => "red",
    "triggered" => "red",
    "warning" => "red",

    # Color - Yellow
    "yellow" => "yellow",
    "acknowledged" => "yellow",
    "notice" => "yellow",

    # Color - Green
    "green" => "green",
    "normal" => "green",

    # Color - Gray
    "gray" => "gray",
    "grey" => "gray"
  }

  @doc """
  Return a status color
  """
  def get_status_color(value, default \\ "gray") do
    key =
      value
      |> Artemis.Helpers.to_string()
      |> String.downcase()
      |> String.trim()

    Map.get(@status_color_lookup, key, default)
  end

  @doc """
  Render a status dot
  """
  def render_status_dot(value, options \\ []) do
    size = Keyword.get(options, :size, "tiny")
    color = get_status_color(value)
    class = "status-dot ui empty circular label #{size} #{color}"

    content_tag(:span, nil, class: class)
  end

  @doc """
  Render status label
  """
  def render_status_label(value, options \\ []) do
    color = Keyword.get(options, :color, get_status_color(value))

    content_tag(:span, value, class: "status-label #{color}")
  end
end
