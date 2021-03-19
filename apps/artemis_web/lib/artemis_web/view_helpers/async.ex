defmodule ArtemisWeb.ViewHelper.Async do
  use Phoenix.HTML

  @moduledoc """
  View helpers for rendering data asynchronously using Phoenix LiveView
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

    <%= async_render(@conn, assigns, "index/_example.html", async_data: {ArtemisWeb.HomeView, :hello_world}) %1> %>
    <%= async_render(@conn, assigns, "index/_example.html", async_data: fn _callback_pid, _assigns -> "Async data: Hello World" end) %>
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
      value = Map.get(assigns, :socket) -> value
      true -> nil
    end
  end
end
