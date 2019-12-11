defmodule Artemis.Helpers.PagerDuty do
  @moduledoc """
  Helper functions for PagerDuty
  """

  @doc """
  Return PagerDuty web url defined in the config
  """
  def get_pager_duty_web_url() do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.fetch!(:web_url)
  end

  @doc """
  Return PagerDuty teams defined in the config
  """
  def get_pager_duty_teams() do
    :artemis
    |> Application.fetch_env!(:pager_duty)
    |> Keyword.fetch!(:teams)
  end

  @doc """
  Return a list of PagerDuty team_ids defined in the config
  """
  def get_pager_duty_team_ids() do
    Enum.map(get_pager_duty_teams(), &Keyword.get(&1, :id))
  end

  @doc """
  Return PagerDuty team by slug
  """
  def get_pager_duty_team_by_slug(slug) do
    Enum.find(get_pager_duty_teams(), fn team ->
      Keyword.get(team, :slug) == slug
    end)
  end

  @doc """
  Return the name of a PagerDuty team defined in the config by team_id
  """
  def get_pager_duty_team_name(team_id) do
    team =
      Enum.find(get_pager_duty_teams(), fn team ->
        Keyword.get(team, :id) == team_id
      end) || []

    Keyword.get(team, :name)
  end
end
