defmodule ArtemisWeb.ApplicationConfigController do
  use ArtemisWeb, :controller

  @allowed_application_configs [
    :artemis,
    :artemis_api,
    :artemis_log,
    :artemis_notify,
    :artemis_web
  ]

  def index(conn, _params) do
    authorize(conn, "application-configs:list", fn ->
      assigns = [
        application_configs: @allowed_application_configs
      ]

      render(conn, "index.html", assigns)
    end)
  end

  def show(conn, %{"id" => id}) do
    authorize(conn, "application-configs:show", fn ->
      assigns = [
        application_config: get_application_config(id),
        application_id: id
      ]

      render(conn, "show.html", assigns)
    end)
  end

  # Helpers

  defp get_application_config(id) do
    application = String.to_existing_atom(id)
    allowed? = Enum.member?(@allowed_application_configs, application)

    case allowed? do
      true -> Application.get_all_env(application)
      false -> {:error, "Invalid Application"}
    end
  end
end
