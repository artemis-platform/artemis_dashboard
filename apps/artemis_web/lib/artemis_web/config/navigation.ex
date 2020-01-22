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
      Application: [
        [
          label: "Application Configs",
          path: &Routes.application_config_path(&1, :index),
          verify: &has?(&1, "application-configs:list")
        ]
      ],
      Clouds: [
        [
          label: "List Clouds",
          path: &Routes.cloud_path(&1, :index),
          verify: &has?(&1, "clouds:list")
        ],
        [
          label: "Create New Cloud",
          path: &Routes.cloud_path(&1, :new),
          verify: &has?(&1, "clouds:create")
        ]
      ],
      Customers: [
        [
          label: "List Customers",
          path: &Routes.customer_path(&1, :index),
          verify: &has?(&1, "customers:list")
        ],
        [
          label: "Create New Customer",
          path: &Routes.customer_path(&1, :new),
          verify: &has?(&1, "customers:create")
        ]
      ],
      "Data Centers": [
        [
          label: "List Data Centers",
          path: &Routes.data_center_path(&1, :index),
          verify: &has?(&1, "data-centers:list")
        ],
        [
          label: "Create New Data Center",
          path: &Routes.data_center_path(&1, :new),
          verify: &has?(&1, "data-centers:create")
        ]
      ],
      Documentation: [
        [
          label: "View Documentation",
          path: &Routes.wiki_page_path(&1, :index),
          verify: &has?(&1, "wiki-pages:list")
        ]
      ],
      "Event Log": [
        [
          label: "View Event Logs",
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
      "HTTP Request Logs": [
        [
          label: "View HTTP Request Logs",
          path: &Routes.http_request_log_path(&1, :index),
          verify: &has?(&1, "http-request-logs:list")
        ]
      ],
      Incidents: [
        [
          label: "List Incidents",
          path: &Routes.incident_path(&1, :index),
          verify: &has?(&1, "incidents:list")
        ]
      ],
      Machines: [
        [
          label: "List Machines",
          path: &Routes.machine_path(&1, :index),
          verify: &has?(&1, "machines:list")
        ],
        [
          label: "Create New Machine",
          path: &Routes.machine_path(&1, :new),
          verify: &has?(&1, "machines:create")
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
      Sessions: [
        [
          label: "View Sessions",
          path: &Routes.session_path(&1, :index),
          verify: &has?(&1, "sessions:list")
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
