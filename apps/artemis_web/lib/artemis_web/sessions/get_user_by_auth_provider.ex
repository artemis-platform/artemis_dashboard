defmodule ArtemisWeb.GetUserByAuthProvider do
  alias Artemis.CreateUser
  alias Artemis.GetSystemUser
  alias Artemis.GetRole
  alias Artemis.GetUser
  alias Artemis.UpdateUser

  @default_role "default"

  def call(%{"id" => provider} = params) do
    available_providers = %{
      "local" => fn () -> get_from_config(params) end
    }

    enabled_providers = :artemis_web
      |> Application.get_env(:auth_providers, "")
      |> String.split(",")

    providers = Map.take(available_providers, enabled_providers)

    case Map.get(providers, provider) do
      nil -> {:error, "Error provider not supported"}
      action -> action.()
    end
  end

  defp get_from_config(_params) do
    case Application.get_env(:artemis, :system_user) do
      nil -> {:error, "Error fetching data from provider"}
      user_data -> create_or_update_user(user_data.email, user_data)
    end
  end

  defp create_or_update_user(email, data) do
    system_user = GetSystemUser.call()

    case GetUser.call([email: email], system_user) do
      nil -> create_user(data, system_user)
      user -> UpdateUser.call(user.id, data, system_user)
    end
  end

  defp create_user(params, system_user) do
    default_role = GetRole.call([slug: @default_role], system_user)

    params
    |> Map.put(:user_roles, [%{role_id: default_role.id}])
    |> CreateUser.call(system_user)
  end
end
