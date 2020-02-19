defmodule ArtemisWeb.HomeView do
  use ArtemisWeb, :view

  @doc """
  Live Render data center list
  """
  def render_summary_data_centers_list_live(conn, options \\ []) do
    session =
      options
      |> Enum.into(%{})
      |> Map.put(:user, current_user(conn))

    Phoenix.LiveView.live_render(conn, ArtemisWeb.SummaryDataCentersListLive, session: session)
  end

  @doc """
  Live Render data center map
  """
  def render_summary_data_centers_map_live(conn) do
    assigns = [
      conn: conn,
      id: "am-chart-#{Artemis.Helpers.UUID.call()}",
      user: current_user(conn)
    ]

    render(ArtemisWeb.LayoutView, "summary_data_centers_map.html", assigns)
  end

  @doc """
  Live Render summary count
  """
  def render_summary_count_live(conn, options) do
    session =
      options
      |> Enum.into(%{})
      |> Map.put(:user, current_user(conn))

    Phoenix.LiveView.live_render(conn, ArtemisWeb.SummaryCountLive, session: session)
  end
end
