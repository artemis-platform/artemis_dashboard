defmodule Artemis.Repo.GenerateData do
  import Ecto.Query

  alias Artemis.Feature
  alias Artemis.Permission
  alias Artemis.Repo
  alias Artemis.Role
  alias Artemis.Tag
  alias Artemis.User
  alias Artemis.UserRole
  alias Artemis.WikiPage

  @moduledoc """
  Defines the minimum data required for the application to run.

  Should be run each time new code is deployed to ensure application integrity.

  To prevent data collisions, each section must be idempotent - only attempting
  to create data when it is not present.

  Note: Filler data used for development, qa, test and demo environments should
  be defined in `Artemis.Repo.GenerateFillerData` instead.
  """

  def call() do
    # Features

    features = [
      %{slug: "global-search", name: "Global Search", active: true}
    ]

    Enum.map(features, fn params ->
      case Repo.get_by(Feature, slug: params.slug) do
        nil ->
          %Feature{}
          |> Feature.changeset(params)
          |> Repo.insert!()

        _ ->
          :ok
      end
    end)

    # Roles

    roles = [
      %{slug: "developer", name: "Site Developer"},
      %{slug: "default", name: "Default"}
    ]

    Enum.map(roles, fn params ->
      case Repo.get_by(Role, slug: params.slug) do
        nil ->
          %Role{}
          |> Role.changeset(params)
          |> Repo.insert!()

        _ ->
          :ok
      end
    end)

    # Permissions

    admin_only = "Should be restricted to administrators"

    permissions = [
      %{slug: "comments:access:all", name: "Comments - Access All", description: admin_only},
      %{slug: "comments:access:self", name: "Comments - Access Self"},
      %{slug: "event-logs:access:all", name: "Event Logs - Access All", description: admin_only},
      %{slug: "event-logs:access:self", name: "Event Logs - Access Self"},
      %{slug: "event-logs:list", name: "Event Logs - List"},
      %{slug: "event-logs:show", name: "Event Logs - Show"},
      %{slug: "features:create", name: "Features - Create"},
      %{slug: "features:delete", name: "Features - Delete"},
      %{slug: "features:list", name: "Features - List"},
      %{slug: "features:show", name: "Features - Show"},
      %{slug: "features:update", name: "Features - Update"},
      %{slug: "http-request-logs:access:all", name: "HTTP Request Logs - Access All", description: admin_only},
      %{slug: "http-request-logs:access:self", name: "HTTP Request Logs - Access Self"},
      %{slug: "http-request-logs:list", name: "HTTP Request Logs - List"},
      %{slug: "http-request-logs:show", name: "HTTP Request Logs - Show"},
      %{slug: "incidents:delete", name: "Incidents - Delete"},
      %{slug: "incidents:list", name: "Incidents - List"},
      %{slug: "incidents:show", name: "Incidents - Show"},
      %{slug: "incidents:create:comments", name: "Incidents - Create Comments"},
      %{slug: "incidents:delete:comments", name: "Incidents - Delete Comments"},
      %{slug: "incidents:list:comments", name: "Incidents - List Comments"},
      %{slug: "incidents:update:comments", name: "Incidents - Update Comments"},
      %{slug: "incidents:create:tags", name: "Incidents - Create New Tags"},
      %{slug: "incidents:update:tags", name: "Incidents - Update Tags"},
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
      %{slug: "jobs:create", name: "Jobs - Create"},
      %{slug: "jobs:delete", name: "Jobs - Delete"},
      %{slug: "jobs:list", name: "Jobs - List"},
      %{slug: "jobs:show", name: "Jobs - Show"},
      %{slug: "jobs:update", name: "Jobs - Update"},
      %{slug: "tags:create", name: "Tags - Global Create", description: admin_only},
      %{slug: "tags:delete", name: "Tags - Global Delete", description: admin_only},
      %{slug: "tags:list", name: "Tags - Global List", description: admin_only},
      %{slug: "tags:show", name: "Tags - Global Show", description: admin_only},
      %{slug: "tags:update", name: "Tags - Global Update", description: admin_only},
      %{slug: "user-impersonations:create", name: "User Impersonations - Create"},
      %{slug: "users:access:all", name: "Users - Access All", description: admin_only},
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
      %{slug: "wiki-pages:create:tags", name: "Docs - Create New Tags"},
      %{slug: "wiki-pages:update:tags", name: "Docs - Update Tags"},
      %{slug: "wiki-revisions:delete", name: "Doc Revisions - Delete"},
      %{slug: "wiki-revisions:list", name: "Doc Revisions - List"},
      %{slug: "wiki-revisions:show", name: "Doc Revisions - Show"}
    ]

    Enum.map(permissions, fn params ->
      case Repo.get_by(Permission, slug: params.slug) do
        nil ->
          %Permission{}
          |> Permission.changeset(params)
          |> Repo.insert!()

        _ ->
          :ok
      end
    end)

    # Role Permissions - Developer Role

    permissions = Repo.all(Permission)

    role =
      Role
      |> preload([:permissions, :user_roles])
      |> Repo.get_by(slug: "developer")

    role
    |> Role.associations_changeset(%{permissions: permissions})
    |> Repo.update!()

    # Role Permissions - Default Role

    permission_slugs = [
      "event-logs:access:self",
      "users:access:self",
      "users:show"
    ]

    permissions =
      Permission
      |> where([p], p.slug in ^permission_slugs)
      |> Repo.all()

    role =
      Role
      |> preload([:permissions, :user_roles])
      |> Repo.get_by(slug: "default")

    role
    |> Role.associations_changeset(%{permissions: permissions})
    |> Repo.update!()

    # Users

    users = [
      Application.fetch_env!(:artemis, :users)[:root_user],
      Application.fetch_env!(:artemis, :users)[:system_user]
    ]

    Enum.map(users, fn params ->
      case Repo.get_by(User, email: params.email) do
        nil ->
          params =
            params
            |> Map.put(:client_key, Artemis.Helpers.random_string(30))
            |> Map.put(:client_secret, Artemis.Helpers.random_string(100))

          %User{}
          |> User.changeset(params)
          |> Repo.insert!()

        _ ->
          :ok
      end
    end)

    # User Roles

    role = Repo.get_by!(Role, slug: "developer")

    user_emails = [
      Application.fetch_env!(:artemis, :users)[:root_user].email,
      Application.fetch_env!(:artemis, :users)[:system_user].email
    ]

    users = Enum.map(user_emails, &Repo.get_by!(User, email: &1))

    Enum.map(users, fn user ->
      case Repo.get_by(UserRole, role_id: role.id, user_id: user.id) do
        nil ->
          params = %{
            created_by_id: user.id,
            role_id: role.id,
            user_id: user.id
          }

          %UserRole{}
          |> UserRole.changeset(params)
          |> Repo.insert!()

        _ ->
          :ok
      end
    end)

    # Tags

    tags = [
      %{name: "Help", slug: "help", type: "wiki-pages"},
      %{name: "Links", slug: "links", type: "wiki-pages"}
    ]

    Enum.map(tags, fn params ->
      case Repo.get_by(Tag, slug: params.slug, type: params.type) do
        nil ->
          %Tag{}
          |> Tag.changeset(params)
          |> Repo.insert!()

        _ ->
          :ok
      end
    end)

    # Wiki Pages

    system_user = Artemis.GetSystemUser.call!()
    help_tag = Repo.get_by(Tag, slug: "help", type: "wiki-pages")

    help_body = """
    Artemis Dashboard is an example of an operational dashboard built on top of Artemis Platform.

    Learn more about [Artemis Dashboard on GitHub](https://github.com/artemis-platform/artemis_dashboard).
    """

    example_body = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc erat augue, maximus ut congue vitae, tincidunt ut neque.

    ## Features

    ### Dynamic Sidebar with Scroll Progress

    The dynamic sidebar on the left side of the page acts as a quick find navigation. It scrolls along with the page and marks the current position.

    ### Full Text Search Support

    All documentation pages support full text search on their content. For example, search for "Lorem ipsum" in the search input at the very top of the page. This documentation page will show up in the results.

    ### Tagging and Comments

    Each documentation page supports user comments and tags.

    ### Revision History

    A revision is captured each time the file changes.

    ### Lists

    Different list types are supported.

    #### Unordered Lists

    - Fusce tempus laoreet arcu
    	- A posuere est vehicula sit amet
    		- Duis sit amet interdum urna
    			- Mauris in turpis quis nisi elementum dignissim a quis ligula
    			- Aenean sit amet velit efficitur
    - Dictum odio eget volutpat quam

    #### Ordered Lists

    1. Fusce tempus laoreet arcu
    	1. A posuere est vehicula sit amet
    		1. Duis sit amet interdum urna
    			1. Mauris in turpis quis nisi elementum dignissim a quis ligula
    			1. Aenean sit amet velit efficitur
    1. Dictum odio eget volutpat quam

    #### Checklists

    Phasellus luctus ultricies egestas:

    - [x] Praesent et interdum ligula
      - [x] Pellentesque congue mi sit amet lacus elementum, vel dapibus tellus volutpat
      - [ ] Suspendisse vitae massa at purus mattis lacinia ac sit amet lacus
    - [ ] Fusce mollis lobortis suscipit
    - [x] Suspendisse at erat at dolor maximus feugiat
    - [ ] Duis ultrices non leo nec consequat
    - [ ] Nulla facilisi

    ### Code Blocks

    Code blocks are supported, along with syntax highlighting via `highlightjs`:

    ```elixir
    defmodule ArtemisLog.Filter do
      import ArtemisLog.Helpers, only: [deep_take: 2]

      def call(%{__struct__: struct} = data) do
        case defined_log_fields?(struct) do
          true -> deep_take(data, struct.event_log_fields())
          false -> data
        end
      end
      def call(data), do: data

      defp defined_log_fields?(struct) do
        struct.__info__(:functions)
        |> Keyword.keys
        |> Enum.member?(:event_log_fields)
      end
    end
    ```

    ## Paragraphs and Headers

    Facilisis mauris sed, egestas tortor. Sed lobortis ut ipsum pulvinar semper. Aliquam egestas nulla purus, eget porta libero semper ut.

    Donec pretium feugiat nunc non venenatis. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.

    Donec ullamcorper, sem sed tempor vulputate, risus augue faucibus sem, quis rutrum turpis sem sit amet libero.

    ### Praesent ac Ipsum

    Sem tempus placerat porta ut felis. Nunc lacinia sodales nulla in pellentesque.

    #### Sed at Nisi

    In ac ante urna. Praesent et tellus lobortis, cursus arcu et, tempor magna. Vivamus justo tellus, fringilla at mauris dignissim, placerat interdum metus.

    #### Integer Pharetra Varius Sapien

    Fusce varius, diam ac convallis commodo, neque diam hendrerit neque, nec vehicula arcu metus nec orci. Proin non placerat diam.

    #### Vitae Convallis

    Nunc rhoncus ligula quis ex pulvinar placerat. Praesent ultricies ut nisi ac tincidunt. Sed eleifend est elit, nec efficitur arcu imperdiet vel. Mauris malesuada, lorem ac sollicitudin aliquet, elit orci sagittis purus, sed vulputate lacus felis nec risus. Phasellus nibh ante, feugiat non nisl in, tempor finibus ex. Ut interdum mollis pulvinar. Nunc in scelerisque mi.
    """

    wiki_pages = [
      %{
        body: help_body,
        section: "Artemis Dashboard",
        slug: "artemis-dashboard-help",
        tags: [%{id: help_tag.id}],
        title: "Artemis Dashboard Help",
        user_id: system_user.id
      },
      %{
        body: example_body,
        section: "Artemis Dashboard",
        slug: "documentation-example",
        tags: [%{id: help_tag.id}],
        title: "Documentation Example",
        user_id: system_user.id
      }
    ]

    Enum.map(wiki_pages, fn params ->
      case Repo.get_by(WikiPage, section: params.section, slug: params.slug) do
        nil ->
          Artemis.CreateWikiPage.call!(params, system_user)

        _ ->
          :ok
      end
    end)

    # Return Value

    {:ok, []}
  end
end
