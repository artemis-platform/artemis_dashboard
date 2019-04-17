defmodule Artemis.Repo.Seeds do
  import Ecto.Query

  alias Artemis.Permission
  alias Artemis.Repo
  alias Artemis.Role
  alias Artemis.User
  alias Artemis.UserRole

  def call() do

    # Roles

    roles = [
      %{slug: "developer", name: "Site Developer"},
      %{slug: "default", name: "Default"},
    ]

    Enum.map(roles, fn (params) ->
      case Repo.get_by(Role, slug: params.slug) do
        nil ->
          %Role{}
          |> Role.changeset(params)
          |> Repo.insert!
        _ ->
          :ok
      end
    end)

    # Permissions

    permissions = [
      %{slug: "comments:access:all", name: "Comments - Access All", description: "Should be restricted to administrators"},
      %{slug: "comments:access:self", name: "Comments - Access Self"},

      %{slug: "event-logs:access:all", name: "Event Logs - Access All", description: "Should be restricted to administrators"},
      %{slug: "event-logs:access:self", name: "Event Logs - Access Self"},
      %{slug: "event-logs:list", name: "Event Logs - List"},
      %{slug: "event-logs:show", name: "Event Logs - Show"},

      %{slug: "features:create", name: "Features - Create"},
      %{slug: "features:delete", name: "Features - Delete"},
      %{slug: "features:list", name: "Features - List"},
      %{slug: "features:show", name: "Features - Show"},
      %{slug: "features:update", name: "Features - Update"},

      %{slug: "help:list", name: "Help - List"},

      %{slug: "http-request-logs:access:all", name: "HTTP Request Logs - Access All", description: "Should be restricted to administrators"},
      %{slug: "http-request-logs:access:self", name: "HTTP Request Logs - Access Self"},
      %{slug: "http-request-logs:list", name: "HTTP Request Logs - List"},
      %{slug: "http-request-logs:show", name: "HTTP Request Logs - Show"},

      %{slug: "permissions:create", name: "Permissions - Create"},
      %{slug: "permissions:delete", name: "Permissions - Delete"},
      %{slug: "permissions:list", name: "Permissions - List"},
      %{slug: "permissions:show", name: "Permissions - Show"},
      %{slug: "permissions:update", name: "Permissions - Update"},

      %{slug: "roles:create", name: "Roles - Create"},
      %{slug: "roles:delete", name: "Roles - Delete"},
      %{slug: "roles:list", name: "Roles - List"},
      %{slug: "roles:show", name: "Roles - Show"},
      %{slug: "roles:update", name: "Roles - Update"},

      %{slug: "user-impersonations:create", name: "User Impersonations - Create"},

      %{slug: "users:access:all", name: "Users - Access All", description: "Should be restricted to administrators"},
      %{slug: "users:access:self", name: "Users - Access Self"},
      %{slug: "users:create", name: "Users - Create"},
      %{slug: "users:delete", name: "Users - Delete"},
      %{slug: "users:list", name: "Users - List"},
      %{slug: "users:show", name: "Users - Show"},
      %{slug: "users:update", name: "Users - Update"},

      %{slug: "wiki-pages:create", name: "Docs - Create"},
      %{slug: "wiki-pages:delete", name: "Docs - Delete"},
      %{slug: "wiki-pages:list", name: "Docs - List"},
      %{slug: "wiki-pages:show", name: "Docs - Show"},
      %{slug: "wiki-pages:update", name: "Docs - Update"},
      %{slug: "wiki-pages:create:comments", name: "Docs - Create Comments"},
      %{slug: "wiki-pages:delete:comments", name: "Docs - Delete Comments"},
      %{slug: "wiki-pages:list:comments", name: "Docs - List Comments"},
      %{slug: "wiki-pages:update:comments", name: "Docs - Update Comments"},

      %{slug: "wiki-revisions:delete", name: "Doc Revisions - Delete"},
      %{slug: "wiki-revisions:list", name: "Doc Revisions - List"},
      %{slug: "wiki-revisions:show", name: "Doc Revisions - Show"}
    ]

    Enum.map(permissions, fn (params) ->
      case Repo.get_by(Permission, slug: params.slug) do
        nil ->
          %Permission{}
          |> Permission.changeset(params)
          |> Repo.insert!
        _ ->
          :ok
      end
    end)

    # Role Permissions - Developer Role

    permissions = Repo.all(Permission)

    role = Role
      |> preload([:permissions, :user_roles])
      |> Repo.get_by(slug: "developer")

    role
    |> Role.associations_changeset(%{permissions: permissions})
    |> Repo.update!

    # Role Permissions - Default Role

    permission_slugs = [
      "comments:access:self",

      "event-logs:access:self",

      "help:list",

      "http-request-logs:access:self",

      "users:access:self",
      "users:show",

      "wiki-pages:list",
      "wiki-pages:show",
      "wiki-pages:create:comments",
      "wiki-pages:delete:comments",
      "wiki-pages:list:comments",
      "wiki-pages:update:comments",

      "wiki-revisions:list",
      "wiki-revisions:show"
    ]

    permissions = Permission
      |> where([p], p.slug in ^permission_slugs)
      |> Repo.all()

    role = Role
      |> preload([:permissions, :user_roles])
      |> Repo.get_by(slug: "default")

    role
    |> Role.associations_changeset(%{permissions: permissions})
    |> Repo.update!

    # Users

    users = [
      Application.fetch_env!(:artemis, :root_user),
      Application.fetch_env!(:artemis, :system_user)
    ]

    Enum.map(users, fn (params) ->
      case Repo.get_by(User, email: params.email) do
        nil ->
          params = params
            |> Map.put(:client_key, Artemis.Helpers.random_string(30))
            |> Map.put(:client_secret, Artemis.Helpers.random_string(100))

          %User{}
          |> User.changeset(params)
          |> Repo.insert!
        _ ->
          :ok
      end
    end)

    # User Roles

    role = Repo.get_by!(Role, slug: "developer")

    user_emails = [
      Application.fetch_env!(:artemis, :root_user).email,
      Application.fetch_env!(:artemis, :system_user).email
    ]
    users = Enum.map(user_emails, &Repo.get_by!(User, email: &1))

    Enum.map(users, fn(user) ->
      case Repo.get_by(UserRole, role_id: role.id, user_id: user.id) do
        nil ->
          params = %{
            created_by_id: user.id,
            role_id: role.id,
            user_id: user.id
          }

          %UserRole{}
          |> UserRole.changeset(params)
          |> Repo.insert!
        _ ->
          :ok
      end
    end)
  end
end
