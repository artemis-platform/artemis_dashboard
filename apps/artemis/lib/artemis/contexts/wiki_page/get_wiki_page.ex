defmodule Artemis.GetWikiPage do
  use Artemis.Context

  import Ecto.Query

  alias Artemis.Repo
  alias Artemis.WikiPage

  @default_preload [:tags, :user]

  def call!(value, _user, options \\ []) do
    get_record(value, options, &Repo.get_by!/2)
  end

  def call(value, _user, options \\ []) do
    get_record(value, options, &Repo.get_by/2)
  end

  defp get_record(value, options, get_by) when not is_list(value) do
    get_record([id: value], options, get_by)
  end

  defp get_record(value, options, get_by) do
    WikiPage
    |> select_query(WikiPage, options)
    |> preload(^Keyword.get(options, :preload, @default_preload))
    |> get_by.(value)
  end
end
