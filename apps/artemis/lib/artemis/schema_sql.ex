defmodule Artemis.Schema.SQL do
  @moduledoc """
  Adds SQL specific schema functions
  """

  defmacro __using__(_options) do
    quote do
      alias Artemis.Repo

      def unique_values_for(field) do
        __MODULE__
        |> select(^[field])
        |> distinct(^field)
        |> order_by(asc: ^field)
        |> Repo.all()
        |> Enum.map(&Map.get(&1, field))
        |> Enum.reject(&is_nil(&1))
      end

      def unique_select_values_for(label, value \\ :id) do
        __MODULE__
        |> select(^[label, value])
        |> distinct(^label)
        |> order_by(asc: ^label)
        |> Repo.all()
        |> Enum.reject(&is_nil(Map.get(&1, label)))
        |> Enum.map(&[Map.get(&1, value), Map.get(&1, label)])
      end
    end
  end
end
