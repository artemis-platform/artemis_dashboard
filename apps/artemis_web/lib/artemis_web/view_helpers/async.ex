defmodule ArtemisWeb.ViewHelper.Async do
  use Phoenix.HTML

  import ArtemisWeb.ViewHelper.Print
  import ArtemisWeb.ViewHelper.Status

  @moduledoc """
  View helpers for rendering data asynchronously using Phoenix LiveView

  NOTE: This module contains async functions. Also see
  `apps/artemis_web/lib/artemis_web.ex` for async related macros.
  """

  @doc """
  Render a template asynchronously.

  ### Optional - Support for Async Data

  Supports a function to be evaluated after page load. Can be passed as either
  a {Module, :function} tuple, function, or anonymous function. Any other data
  will simulate an asynchronous data call, returning the response immediately.

  The results of the async data call is available in the `@async_data` assigned
  variable. When loading the value is `nil`.

  The default value for this option is `nil`.

  Example:

    <%= async_render(@conn, assigns, "index/_example.html", async_data: fn _callback_pid, _assigns -> "Async data: Hello World" end) %>
    <%= async_render @conn, assigns, "index/_example.html", async_data: &hello_world_data/2 %>
    <%= async_render(@conn, assigns, "index/_example.html", async_data: {ArtemisWeb.HomeView, :hello_world_data}) %1> %>
    <%= async_render(@conn, assigns, "index/_example.html", async_data: "Fake async data to be returned") %>

  """
  def async_render(conn, assigns, template, options \\ []) do
    id = Keyword.get(options, :id, template)
    session = async_convert_assigns_to_session(assigns, template, options)

    Phoenix.LiveView.Helpers.live_render(conn, ArtemisWeb.AsyncRenderLive, id: id, session: session)
  end

  @doc """
  Helper for converting an assigns into session
  """
  def async_convert_assigns_to_session(assigns, template, options \\ []) do
    module = Keyword.get(options, :module, assigns[:view_module] || assigns[:module])
    async_data = Keyword.get(options, :async_data, assigns[:async_data])

    assigns
    |> Enum.into(%{})
    |> Map.delete(:conn)
    |> Enum.map(fn {key, value} -> {Artemis.Helpers.to_string(key), value} end)
    |> Enum.into(%{})
    |> Map.put("async_data", maybe_serialize_async_data(async_data))
    |> Map.put("module", module)
    |> Map.put("template", template)
  end

  defp maybe_serialize_async_data(value) when is_function(value), do: ArtemisWeb.AsyncRenderLive.serialize(value)
  defp maybe_serialize_async_data(value), do: value

  @doc """
  Return whether async data is loaded. Can be used in a template `if` statement
  to evaluate sections waiting on async data

  Example

      <%= if async_loaded?(assigns) do %>
        Custom HTML here
      <% end %>

  """
  def async_loaded?(assigns) do
    async_status = Map.get(assigns, :async_status)

    cond do
      async_status == :loading -> false
      true -> true
    end
  end

  @doc """
  Render async render information
  """
  def render_page_data_info(assigns, options \\ []) do
    async_status = Map.get(assigns, :async_status)
    loading? = Enum.member?([:loading, :reloading], Map.get(assigns, :async_status))
    color = if async_status == :reloading, do: "orange", else: "green"
    icon = if loading?, do: "ui icon sync alternate rotating #{color}", else: "ui icon check green"
    updated_at = Keyword.get(options, :updated_at) || Timex.now()

    content_tag(:div, class: "page-data-info") do
      [
        render_async_data_info(assigns),
        content_tag(:div, content_tag(:i, "", class: icon)),
        content_tag(:div, "Last updated on #{render_date_time_with_seconds(updated_at)}")
      ]
    end
  end

  @doc """
  Render reloading information
  """
  def render_async_data_info(assigns) do
    case Map.get(assigns, :async_status) do
      :loading -> render_status_label("Loading", color: "green")
      :reloading -> render_status_label("Updating", color: "orange")
      _ -> ""
    end
  end

  @doc """
  Render a reloading icon
  """
  def render_async_reloading_icon(assigns) do
    if Map.get(assigns, :async_status) == :reloading do
      content_tag(:div, "", class: "ui active centered inline loader")
    end
  end

  @doc """
  Return async data field
  """
  def get_async_data_field(assigns, field) do
    Artemis.Helpers.deep_get(assigns, [:async_data, field])
  end

  @doc """
  Return either @conn or @socket depending on which is set
  """
  def get_conn_or_socket(assigns) do
    cond do
      value = Map.get(assigns, :conn) -> value
      value = Map.get(assigns, :conn_or_socket) -> value
      value = Map.get(assigns, :socket) -> value
      true -> nil
    end
  end
end
