defmodule Artemis.GetTag do
  use Artemis.Context

  import Ecto.Query

  alias Artemis.Tag
  alias Artemis.Repo

  @default_preload []

  def call!(value, user, options \\ []) do
    get_record(value, user, options, &Repo.get_by!/2)
  end

  def call(value, user, options \\ []) do
    get_record(value, user, options, &Repo.get_by/2)
  end

  defp get_record(value, user, options, get_by) when not is_list(value) do
    get_record([id: value], user, options, get_by)
  end

  defp get_record(value, _user, options, get_by) do
    Tag
    |> select_query(Tag, options)
    |> preload(^Keyword.get(options, :preload, @default_preload))
    |> get_by.(value)
  end
end
