defmodule ArtemisWeb.ListSessionAuthProviders do
  alias ArtemisWeb.Router.Helpers, as: Routes

  def call(conn) do
    state = Map.get(conn.query_params, "redirect")

    available_providers = %{
      "local" => %{
        title: "Log in as System User",
        link: Routes.session_path(conn, :show, "local", state: state)
      }
    }

    enabled_providers = :artemis_web
      |> Application.get_env(:auth_providers, "")
      |> String.split(",")

    available_providers
    |> Map.take(enabled_providers)
    |> Enum.map(fn ({_key, value}) -> value end)
  end
end
