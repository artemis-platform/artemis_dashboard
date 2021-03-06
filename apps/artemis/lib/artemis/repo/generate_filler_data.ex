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

    customers = generate_customers(system_user)
    clouds = generate_clouds(customers, system_user)
    data_centers = generate_data_centers(system_user)
    _machines = generate_machines(clouds, data_centers, system_user)

    :ok
  end

  defp generate_incidents(_system_user), do: insert_list(100, :incident)

  defp generate_roles(system_user) do
    roles = [
      %{name: "Executive Viewers", slug: "executive-viewer"},
      %{name: "Client Success Manager", slug: "client-success-manager"},
      %{name: "Network Administrator", slug: "network-administrator"}
    ]

    Enum.map(roles, fn params ->
      case Artemis.GetRole.call([slug: params.slug], system_user) do
        nil -> Artemis.CreateRole.call!(params, system_user)
        record -> record
      end
    end)
  end

  defp generate_users(system_user) do
    users = insert_list(30, :user)
    default_role = Repo.get_by(Role, slug: "default")

    Enum.map(users, fn user ->
      insert(:user_role, created_by: system_user, role: default_role, user: user)
    end)

    users
  end

  defp generate_customers(_system_user), do: insert_list(30, :customer)

  defp generate_data_centers(system_user) do
    data_centers = [
      %{
        name: "Moscow",
        slug: "DME",
        country: "Russia",
        latitude: "55.7558",
        longitude: "37.6173"
      },
      %{
        name: "Paris",
        slug: "CDG",
        country: "France",
        latitude: "48.8566",
        longitude: "2.3522"
      },
      %{
        name: "San Francisco",
        slug: "SFO",
        country: "United States",
        latitude: "37.7749",
        longitude: "-122.4194"
      },
      %{
        name: "Tokyo",
        slug: "TOK",
        country: "Japan",
        latitude: "35.6804",
        longitude: "139.7690"
      },
      %{
        name: "Toronto",
        slug: "TOR",
        country: "Canada",
        latitude: "43.6532",
        longitude: "-79.3832"
      }
    ]

    Enum.map(data_centers, fn params ->
      case Artemis.GetDataCenter.call([slug: params.slug], system_user) do
        nil -> Artemis.CreateDataCenter.call!(params, system_user)
        record -> record
      end
    end)
  end

  defp generate_clouds(customers, _system_user) do
    Enum.map(Range.new(0, 100), fn _ ->
      customer = Enum.random(customers)

      insert(:cloud, customer: customer, machines: [])
    end)
  end

  defp generate_machines(clouds, data_centers, _system_user) do
    Enum.map(clouds, fn cloud ->
      Enum.map(Range.new(3, 16), fn _ ->
        data_center = Enum.random(data_centers)

        insert(:machine, cloud: cloud, data_center: data_center)
      end)
    end)
  end
end
