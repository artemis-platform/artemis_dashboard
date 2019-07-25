defmodule ArtemisWeb.Config.Navigation do
  import ArtemisWeb.UserAccess

  alias ArtemisWeb.Router.Helpers, as: Routes

  @doc """
  List of possible nav items. Each entry should define:

  - label: user facing label for the nav item
  - path: function that takes `conn` as the first argument and returns a string path
  - verify: function that takes the `current_user` as the first argument and returns a boolean
  """
  def get_nav_items do
    Enum.reverse(
      Documentation: [
        [
          label: "View Documentation",
          path: &Routes.wiki_page_path(&1, :index),
          verify: &has?(&1, "wiki-pages:list")
        ]
      ],
      "Event Log": [
        [
          label: "View Event Log",
          path: &Routes.event_log_path(&1, :index),
          verify: &has?(&1, "event-logs:list")
        ]
      ],
      Features: [
        [
          label: "List Features",
          path: &Routes.feature_path(&1, :index),
          verify: &has?(&1, "features:list")
        ],
        [
          label: "Create New Feature",
          path: &Routes.feature_path(&1, :new),
          verify: &has?(&1, "features:create")
        ]
      ],
      Incidents: [
        [
          label: "List Incidents",
          path: &Routes.incident_path(&1, :index),
          verify: &has?(&1, "incidents:list")
        ]
      ],
      "On Call": [
        [
          label: "Overview",
          path: &Routes.on_call_path(&1, :index),
          verify: &has_any?(&1, ["incidents:list"])
        ]
      ],
      Permissions: [
        [
          label: "List Permissions",
          path: &Routes.permission_path(&1, :index),
          verify: &has?(&1, "permissions:list")
        ],
        [
          label: "Create New Permission",
          path: &Routes.permission_path(&1, :new),
          verify: &has?(&1, "permissions:create")
        ]
      ],
      Roles: [
        [
          label: "List Roles",
          path: &Routes.role_path(&1, :index),
          verify: &has?(&1, "roles:list")
        ],
        [
          label: "Create New Role",
          path: &Routes.role_path(&1, :new),
          verify: &has?(&1, "roles:create")
        ]
      ],
      Jobs: [
        [
          label: "List Jobs",
          path: &Routes.job_path(&1, :index),
          verify: &has?(&1, "jobs:list")
        ],
        [
          label: "Create New Job",
          path: &Routes.job_path(&1, :new),
          verify: &has?(&1, "jobs:create")
        ]
      ],
      Tags: [
        [
          label: "List Tags",
          path: &Routes.tag_path(&1, :index),
          verify: &has?(&1, "tags:list")
        ],
        [
          label: "Create New Tag",
          path: &Routes.tag_path(&1, :new),
          verify: &has?(&1, "tags:create")
        ]
      ],
      Users: [
        [
          label: "List Users",
          path: &Routes.user_path(&1, :index),
          verify: &has?(&1, "users:list")
        ],
        [
          label: "Create New User",
          path: &Routes.user_path(&1, :new),
          verify: &has?(&1, "users:create")
        ]
      ]
    )
  end
end
