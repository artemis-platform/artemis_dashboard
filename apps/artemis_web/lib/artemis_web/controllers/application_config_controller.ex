defmodule ArtemisWeb.ApplicationConfigController do
  use ArtemisWeb, :controller

  @allowed_applications [
    :artemis,
    :artemis_api,
    :artemis_log,
    :artemis_notify,
    :artemis_web
  ]

  def index(conn, _params) do
    authorize(conn, "application-configs:list", fn ->
      app_config_enabled?(conn, [:artemis_web, ArtemisWeb.Endpoint, :application_config_page], fn ->
        assigns = [
          application_configs: @allowed_applications
        ]

        render(conn, "index.html", assigns)
      end)
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "application-configs:show", fn ->
      app_config_enabled?(conn, [:artemis_web, ArtemisWeb.Endpoint, :application_config_page], fn ->
        assigns = [
          application_config: get_application_config(id),
          application_id: id,
          application_spec: get_application_spec(id),
          applications_started: Application.started_applications()
        ]

        render(conn, "show.html", assigns)
      end)
    end)
  end

  # Helpers

  defp get_application_config(id) do
    application = String.to_existing_atom(id)
    allowed? = Enum.member?(@allowed_applications, application)

    case allowed? do
      true -> Application.get_all_env(application)
      false -> {:error, "Invalid Application"}
    end
  end

  defp get_application_spec(id) do
    application = String.to_existing_atom(id)
    allowed? = Enum.member?(@allowed_applications, application)

    case allowed? do
      true -> Application.spec(application)
      false -> {:error, "Invalid Application"}
    end
  end
end
