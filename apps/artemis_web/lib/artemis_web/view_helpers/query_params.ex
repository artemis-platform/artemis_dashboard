defmodule ArtemisWeb.ViewHelper.QueryParams do
  use Phoenix.HTML

  @doc """
  Adds or drops values from existing query params.

  Drops any key/value pairs where the final value is either:

      nil
      ""   # Empty Bitstring
      []   # Empty List
      %{}  # Empty Map

  """
  def update_query_params(current_query_params, values) do
    values =
      values
      |> Enum.into(%{})
      |> Artemis.Helpers.keys_to_strings()

    current_query_params
    |> Artemis.Helpers.deep_merge(values)
    |> Artemis.Helpers.deep_drop_by_value(nil)
    |> Artemis.Helpers.deep_drop_by_value("")
    |> Artemis.Helpers.deep_drop_by_value([])
    |> Artemis.Helpers.deep_drop_by_value(%{})
  end

  @doc """
  Renders a button for setting query params in the URL
  """
  def query_param_button(conn, label, values) do
    current_query_params = conn.query_params
    updated_query_params = ArtemisWeb.ViewHelper.QueryParams.update_query_params(current_query_params, values)
    updated_query_string = Plug.Conn.Query.encode(updated_query_params)
    path = "#{conn.request_path}?#{updated_query_string}"

    active? =
      case current_query_params != nil do
        true ->
          updated_size = Artemis.Helpers.deep_size(updated_query_params)
          updated_set = MapSet.new(updated_query_params)

          current_size = Artemis.Helpers.deep_size(current_query_params)
          current_set = MapSet.new(current_query_params)

          add? = current_size <= updated_size
          present? = updated_query_params != %{}
          subset? = MapSet.subset?(updated_set, current_set)

          add? && present? && subset?

        false ->
          false
      end

    class =
      case active? do
        true -> "ui basic button blue"
        false -> "ui basic button"
      end

    options = [
      class: class,
      onclick: "location.href='#{path}'",
      type: "button"
    ]

    content_tag(:button, label, options)
  end
end
