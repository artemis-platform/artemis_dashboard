defmodule Artemis.Helpers.Query do
  @moduledoc """
  Common query helpers
  """

  def filter(query, _params, _module) do
    query
  end

  def paginate(query, _params) do
    query
  end

  def preload(query, _default_preloads, _params \\ %{}) do
    query
  end

  def sort(query, _params, _module) do
    query
  end
end
