defmodule ArtemisWeb.RenderCache do
  use Artemis.ContextCache,
    cache_driver: "cachex",
    cache_key: &custom_cache_key/1

  alias Artemis.GetSystemUser
  alias Artemis.ListFeatures

  def call(_name, callback, _user) do
    callback.()
  end

  def custom_cache_key([name, _callback, user]) do
    [
      active_features: active_features(),
      render_cache_name: name,
      user_permissions: user_permissions(user)
    ]
  end

  defp active_features() do
    GetSystemUser.call_with_cache()
    |> Map.get(:data)
    |> ListFeatures.call_with_cache()
    |> Map.get(:data)
    |> Enum.filter(& &1.active)
    |> Enum.map(& &1.slug)
  end

  defp user_permissions(user) do
    user
    |> Map.get(:permissions)
    |> Enum.map(& &1.slug)
    |> Enum.sort()
  end
end
