defmodule Artemis.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  alias Artemis.Drivers.IBMCloudant

  using do
    quote do
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Artemis.DataCase

      alias Artemis.Mock
      alias Artemis.Repo
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Artemis.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Artemis.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  Delete all documents in database
  """
  def cloudant_delete_all(schema) do
    {:ok, _} = IBMCloudant.Delete.call(schema)
    {:ok, _} = IBMCloudant.Create.call(schema)
    {:ok, _} = IBMCloudant.CreateSearch.call(schema)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  @doc """
  Disable a feature by slug. Will update an existing feature or create a new one.
  """
  def disable_feature(slug), do: toggle_feature(slug, false)

  @doc """
  Enable a feature by slug. Will update an existing feature or create a new one.
  """
  def enable_feature(slug), do: toggle_feature(slug, true)

  defp toggle_feature(slug, active) do
    case Artemis.Repo.get_by(Artemis.Feature, slug: slug) do
      nil ->
        create_params = %{
          active: true,
          name: slug,
          slug: slug
        }

        %Artemis.Feature{}
        |> Artemis.Feature.changeset(create_params)
        |> Artemis.Repo.insert()

      feature ->
        case feature.active == active do
          true ->
            feature

          false ->
            feature
            |> Artemis.Feature.changeset(%{active: active})
            |> Artemis.Repo.update()
        end
    end
  end
end
