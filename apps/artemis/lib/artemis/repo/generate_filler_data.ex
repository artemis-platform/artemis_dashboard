defmodule Artemis.Repo.GenerateFillerData do
  import Artemis.Factories

  alias Artemis.GetSystemUser
  alias Artemis.Repo
  alias Artemis.Role

  @moduledoc """
  Generate consistent data for development, QA, test, and demo environments.

  Requires a verification phrase to be passed to prevent accidental execution.
  """

  @verification_phrase "confirming-generation-of-filler-data"

  def call(verification_phrase) do
    with true <- enabled?(),
         true <- verification_phrase?(verification_phrase) do
      {:ok, generate_data()}
    else
      error -> error
    end
  end

  def verification_phrase, do: @verification_phrase

  defp enabled? do
    config =
      :artemis
      |> Application.fetch_env!(:actions)
      |> Keyword.fetch!(:repo_generate_filler_data)
      |> Keyword.fetch!(:enabled)
      |> String.downcase()
      |> String.equivalent?("true")

    case config do
      false -> {:error, "Action not enabled in the application config"}
      true -> true
    end
  end

  defp verification_phrase?(verification_phrase) do
    case verification_phrase == @verification_phrase do
      false -> {:error, "Action requires valid verification phrase to be passed"}
      true -> true
    end
  end

  defp generate_data do
    system_user = GetSystemUser.call!()

    generate_incidents(system_user)
    generate_roles(system_user)
    generate_users(system_user)
  end

  defp generate_incidents(_system_user), do: insert_list(100, :incident)

  defp generate_roles(_system_user) do
    [
      insert(:role, name: "Executive Viewers", slug: "executive-viewer"),
      insert(:role, name: "Client Success Manager", slug: "client-success-manager"),
      insert(:role, name: "Network Administrator", slug: "network-administrator")
    ]
  end

  defp generate_users(system_user) do
    users = insert_list(30, :user)
    default_role = Repo.get_by(Role, slug: "default")

    Enum.map(users, fn user ->
      insert(:user_role, created_by: system_user, role: default_role, user: user)
    end)

    users
  end
end
