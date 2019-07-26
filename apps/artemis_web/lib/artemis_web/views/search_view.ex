defmodule ArtemisWeb.SearchView do
  use ArtemisWeb, :view

  alias ArtemisWeb.Router.Helpers, as: Routes

  @search_links %{
    "wiki_pages" => [
      label: "Documentation",
      path: &Routes.wiki_page_path/3
    ],
    "features" => [
      label: "Features",
      path: &Routes.feature_path/3
    ],
    "incidents" => [
      label: "Incidents",
      path: &Routes.incident_path/3
    ],
    "jobs" => [
      label: "Jobs",
      path: &Routes.job_path/3
    ],
    "permissions" => [
      label: "Permissions",
      path: &Routes.permission_path/3
    ],
    "roles" => [
      label: "Roles",
      path: &Routes.role_path/3
    ],
    "users" => [
      label: "Users",
      path: &Routes.user_path/3
    ]
  }

  def search_results?(%{total_entries: total_entries}), do: total_entries > 0

  def search_results?(data) do
    Enum.any?(data, fn {_, resource} ->
      Map.get(resource, :total_entries) > 0
    end)
  end

  def search_anchor(key), do: "anchor-#{key}"

  def search_label(key) do
    @search_links
    |> Map.get(key, [])
    |> Keyword.get(:label)
  end

  def search_total(data) do
    Map.get(data, :total_entries)
  end

  def search_link(conn, data, key) do
    label = "View " <> search_matches_text(data)

    path =
      @search_links
      |> Map.get(key, [])
      |> Keyword.get(:path)

    to = path.(conn, :index, current_query_params(conn))

    action(label, to: to)
  end

  def search_matches_text(data) do
    total = search_total(data)

    ngettext("%{total} Match", "%{total} Matches", total, total: total)
  end

  def search_entries(data) do
    data
    |> Map.get(:entries)
    |> Enum.map(&search_entry(&1))
  end

  defp search_entry(%Artemis.Feature{} = data) do
    %{
      title: data.slug,
      permission: "features:show",
      link: fn conn -> Routes.feature_path(conn, :show, data) end
    }
  end

  defp search_entry(%Artemis.Incident{} = data) do
    %{
      title: data.title,
      permission: "incidents:show",
      link: fn conn -> Routes.incident_path(conn, :show, data) end
    }
  end

  defp search_entry(%Artemis.Job{} = data) do
    %{
      title: data._id,
      permission: "jobs:show",
      link: fn conn -> Routes.job_path(conn, :show, data._id) end
    }
  end

  defp search_entry(%Artemis.Permission{} = data) do
    %{
      title: data.slug,
      permission: "permissions:show",
      link: fn conn -> Routes.permission_path(conn, :show, data) end
    }
  end

  defp search_entry(%Artemis.Role{} = data) do
    %{
      title: data.slug,
      permission: "roles:show",
      link: fn conn -> Routes.user_path(conn, :show, data) end
    }
  end

  defp search_entry(%Artemis.User{} = data) do
    %{
      title: data.name,
      permission: "users:show",
      link: fn conn -> Routes.user_path(conn, :show, data) end
    }
  end

  defp search_entry(%Artemis.WikiPage{} = data) do
    %{
      title: data.title,
      permission: "wiki-pages:show",
      link: fn conn -> Routes.wiki_page_path(conn, :show, data) end
    }
  end

  def search_entries_total(data) do
    data
    |> search_entries()
    |> length()
  end

  # Helpers

  defp current_query_params(conn) do
    Enum.into(conn.query_params, [])
  end
end
