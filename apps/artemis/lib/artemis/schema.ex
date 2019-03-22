defmodule Artemis.Schema do
  @callback fields :: List.t
  @callback required :: List.t

  defmacro __using__(_opts) do
    quote do
      use Ecto.Schema

      import Ecto
      import Ecto.Changeset
      import Ecto.Query

      alias __MODULE__
      alias Artemis.Repo
      alias Artemis.Schema

      def unique_values_for(field) do
        __MODULE__
        |> select(^[field])
        |> distinct(^field)
        |> order_by(asc: ^field)
        |> Repo.all
        |> Enum.map(&Map.get(&1, field))
        |> Enum.reject(&is_nil(&1))
      end
    end
  end
end
