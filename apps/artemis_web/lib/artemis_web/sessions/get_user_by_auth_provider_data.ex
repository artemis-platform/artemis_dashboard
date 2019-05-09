defmodule ArtemisWeb.GetUserByAuthProviderData do
  require Logger

  alias Artemis.CreateAuthProvider
  alias Artemis.CreateUser
  alias Artemis.GetSystemUser
  alias Artemis.GetAuthProvider
  alias Artemis.GetRole
  alias Artemis.UpdateAuthProvider
  alias Artemis.UpdateUser

  @default_role "default"

  def call(data, options \\ []) do
    case auth_provider_enabled?(data, options) do
      true -> get_user(data)
      false -> {:error, "Error auth provider not supported"}
    end
  end

  defp auth_provider_enabled?(_data, enable_all_providers: true), do: true
  defp auth_provider_enabled?(data, _options) do
    enabled_providers = :artemis_web
      |> Application.get_env(:auth_providers, [])
      |> Keyword.get(:enabled, "")
      |> String.split(",")

    provider = data
      |> Map.get(:provider)
      |> Artemis.Helpers.to_string()

    Enum.member?(enabled_providers, provider)
  end

  defp get_user(data) do
    system_user = GetSystemUser.call!()
    params = [
      type: Artemis.Helpers.to_string(data.provider),
      uid: Artemis.Helpers.to_string(data.uid)
    ]

    case GetAuthProvider.call(params, system_user) do
      nil -> {:ok, create_user(data, system_user)}
      provider -> {:ok, update_user(data, provider, system_user)}
    end
  rescue
    error -> 
      Logger.debug "Get User by Auth Provider Data Error: " <> inspect(error)
      {:error, "Error processing auth provider data"}
  end

  defp create_user(data, system_user) do
    default_role = GetRole.call([slug: @default_role], system_user)

    user = data
      |> get_user_params()
      |> Map.put("user_roles", [%{"role_id" => default_role.id}])
      |> CreateUser.call!(system_user)

    _provider = data
      |> get_auth_provider_params()
      |> Map.put("user_id", user.id)
      |> CreateAuthProvider.call!(system_user)

    user
  end

  defp get_user_params(data) do
    data
    |> Map.get(:info, %{})
    |> Map.put(:last_log_in_at, DateTime.to_string(DateTime.utc_now()))
    |> Artemis.Helpers.deep_delete(:__struct__)
    |> Artemis.Helpers.keys_to_strings(:__struct__)
  end

  defp get_auth_provider_params(data) do
    provider_data = data
      |> Map.get(:extra, get_user_params(data))
      |> Artemis.Helpers.deep_delete(:__struct__)

    %{}
    |> Map.put(:data, provider_data)
    |> Map.put(:type, Artemis.Helpers.to_string(data.provider))
    |> Map.put(:uid, Artemis.Helpers.to_string(data.uid))
    |> Artemis.Helpers.keys_to_strings(:__struct__)
  end

  defp update_user(data, provider, system_user) do
    user_params = data
      |> get_user_params()
      |> Map.take(["last_log_in_at"])
    
    UpdateAuthProvider.call!(provider.id, get_auth_provider_params(data), system_user)
    UpdateUser.call!(provider.user_id, user_params, system_user)
  end
end
