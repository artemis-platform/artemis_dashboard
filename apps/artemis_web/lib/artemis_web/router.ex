defmodule ArtemisWeb.Router do
  use ArtemisWeb, :router

  require Ueberauth

  pipeline :browser do
    plug :accepts, ["html", "csv"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :read_auth do
    plug :fetch_session
    plug Guardian.Plug.Pipeline, module: ArtemisWeb.Guardian, error_handler: ArtemisWeb.Guardian.ErrorHandler
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.VerifySession
    plug Guardian.Plug.LoadResource, allow_blank: true
  end

  pipeline :require_auth do
    plug ArtemisWeb.Plug.ClientCredentials
    plug ArtemisWeb.Plug.BroadcastRequest
    plug Guardian.Plug.EnsureAuthenticated
  end

  scope "/", ArtemisWeb do
    pipe_through :browser
    pipe_through :read_auth

    scope "/auth" do
      get "/new", AuthController, :new
      get "/:provider", AuthController, :request
      get "/:provider/callback", AuthController, :callback
      post "/:provider/callback", AuthController, :callback
      delete "/logout", AuthController, :delete
    end

    scope "/" do
      pipe_through :require_auth

      get "/", HomeController, :index

      # Application Config

      resources "/application-config", ApplicationConfigController, only: [:index, :show]

      # Clouds

      post "/clouds/bulk-actions", CloudController, :index_bulk_actions
      get "/clouds/event-logs", CloudController, :index_event_log_list
      get "/clouds/event-logs/:id", CloudController, :index_event_log_details

      resources "/clouds", CloudController do
        get "/comments", CloudController, :index_comment, as: :comment
        post "/comments", CloudController, :create_comment, as: :comment
        get "/comments/:id/edit", CloudController, :edit_comment, as: :comment
        patch "/comments/:id", CloudController, :update_comment, as: :comment
        put "/comments/:id", CloudController, :update_comment, as: :comment
        delete "/comments/:id", CloudController, :delete_comment, as: :comment

        get "/event-logs", CloudController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", CloudController, :show_event_log_details, as: :event_log
      end

      # Customers

      post "/customers/bulk-actions", CustomerController, :index_bulk_actions
      get "/customers/event-logs", CustomerController, :index_event_log_list
      get "/customers/event-logs/:id", CustomerController, :index_event_log_details

      resources "/customers", CustomerController do
        get "/comments", CustomerController, :index_comment, as: :comment
        post "/comments", CustomerController, :create_comment, as: :comment
        get "/comments/:id/edit", CustomerController, :edit_comment, as: :comment
        patch "/comments/:id", CustomerController, :update_comment, as: :comment
        put "/comments/:id", CustomerController, :update_comment, as: :comment
        delete "/comments/:id", CustomerController, :delete_comment, as: :comment

        get "/event-logs", CustomerController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", CustomerController, :show_event_log_details, as: :event_log
      end

      # Data Centers

      post "/data-centers/bulk-actions", DataCenterController, :index_bulk_actions
      get "/data-centers/event-logs", DataCenterController, :index_event_log_list
      get "/data-centers/event-logs/:id", DataCenterController, :index_event_log_details

      resources "/data-centers", DataCenterController do
        get "/comments", DataCenterController, :index_comment, as: :comment
        post "/comments", DataCenterController, :create_comment, as: :comment
        get "/comments/:id/edit", DataCenterController, :edit_comment, as: :comment
        patch "/comments/:id", DataCenterController, :update_comment, as: :comment
        put "/comments/:id", DataCenterController, :update_comment, as: :comment
        delete "/comments/:id", DataCenterController, :delete_comment, as: :comment

        get "/event-logs", DataCenterController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", DataCenterController, :show_event_log_details, as: :event_log
      end

      # Docs

      resources "/docs", WikiPageController do
        get "/comments", WikiPageController, :index_comment, as: :comment
        post "/comments", WikiPageController, :create_comment, as: :comment
        get "/comments/:id/edit", WikiPageController, :edit_comment, as: :comment
        patch "/comments/:id", WikiPageController, :update_comment, as: :comment
        put "/comments/:id", WikiPageController, :update_comment, as: :comment
        delete "/comments/:id", WikiPageController, :delete_comment, as: :comment

        resources "/revisions", WikiRevisionController, only: [:index, :show, :delete], as: :revision

        put "/tags", WikiPageTagController, :update, as: :tag
      end

      get "/docs/:id/:slug", WikiPageController, :show

      # Event Logs

      resources "/event-logs", EventLogController, only: [:index, :show]

      # HTTP Requests

      resources "/http-request-logs", HttpRequestLogController, only: [:index, :show]

      # Features

      post "/features/bulk-actions", FeatureController, :index_bulk_actions
      get "/features/event-logs", FeatureController, :index_event_log_list
      get "/features/event-logs/:id", FeatureController, :index_event_log_details

      resources "/features", FeatureController do
        get "/event-logs", FeatureController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", FeatureController, :show_event_log_details, as: :event_log
      end

      # Incidents

      post "/incidents/bulk-actions", IncidentController, :index_bulk_actions

      resources "/incidents", IncidentController, only: [:index, :show, :delete] do
        get "/comments", IncidentController, :index_comment, as: :comment
        post "/comments", IncidentController, :create_comment, as: :comment
        get "/comments/:id/edit", IncidentController, :edit_comment, as: :comment
        patch "/comments/:id", IncidentController, :update_comment, as: :comment
        put "/comments/:id", IncidentController, :update_comment, as: :comment
        delete "/comments/:id", IncidentController, :delete_comment, as: :comment

        put "/tags", IncidentTagController, :update, as: :tag
      end

      # Jobs

      post "/jobs/bulk-actions", JobController, :index_bulk_actions
      get "/jobs/event-logs", JobController, :index_event_log_list
      get "/jobs/event-logs/:id", JobController, :index_event_log_details

      resources "/jobs", JobController do
        get "/comments", JobController, :index_comment, as: :comment
        post "/comments", JobController, :create_comment, as: :comment
        get "/comments/:id/edit", JobController, :edit_comment, as: :comment
        patch "/comments/:id", JobController, :update_comment, as: :comment
        put "/comments/:id", JobController, :update_comment, as: :comment
        delete "/comments/:id", JobController, :delete_comment, as: :comment

        get "/event-logs", JobController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", JobController, :show_event_log_details, as: :event_log
      end

      # Key Value

      post "/key-values/bulk-actions", KeyValueController, :index_bulk_actions
      get "/key-values/event-logs", KeyValueController, :index_event_log_list
      get "/key-values/event-logs/:id", KeyValueController, :index_event_log_details

      resources "/key-values", KeyValueController do
        get "/event-logs", KeyValueController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", KeyValueController, :show_event_log_details, as: :event_log
      end

      # Machines

      post "/machines/bulk-actions", MachineController, :index_bulk_actions
      get "/machines/event-logs", MachineController, :index_event_log_list
      get "/machines/event-logs/:id", MachineController, :index_event_log_details

      resources "/machines", MachineController do
        get "/comments", MachineController, :index_comment, as: :comment
        post "/comments", MachineController, :create_comment, as: :comment
        get "/comments/:id/edit", MachineController, :edit_comment, as: :comment
        patch "/comments/:id", MachineController, :update_comment, as: :comment
        put "/comments/:id", MachineController, :update_comment, as: :comment
        delete "/comments/:id", MachineController, :delete_comment, as: :comment

        get "/event-logs", MachineController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", MachineController, :show_event_log_details, as: :event_log
      end

      # On Call

      get "/on-call/weekly-summary", OnCallController, :index_weekly_summary
      resources "/on-call", OnCallController, only: [:index]

      # Permissions

      post "/permissions/bulk-actions", PermissionController, :index_bulk_actions
      get "/permissions/event-logs", PermissionController, :index_event_log_list
      get "/permissions/event-logs/:id", PermissionController, :index_event_log_details

      resources "/permissions", PermissionController do
        get "/event-logs", PermissionController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", PermissionController, :show_event_log_details, as: :event_log
      end

      # Roles

      post "/roles/bulk-actions", RoleController, :index_bulk_actions
      get "/roles/event-logs", RoleController, :index_event_log_list
      get "/roles/event-logs/:id", RoleController, :index_event_log_details

      resources "/roles", RoleController do
        get "/event-logs", RoleController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", RoleController, :show_event_log_details, as: :event_log
      end

      # Search

      resources "/search", SearchController, only: [:index]

      # Sessions

      resources "/sessions", SessionController, only: [:index, :show]

      # System Tasks

      get "/system-tasks/event-logs", SystemTaskController, :index_event_log_list
      get "/system-tasks/event-logs/:id", SystemTaskController, :index_event_log_details

      resources "/system-tasks", SystemTaskController, only: [:index, :new, :create]

      # Tags

      post "/tags/bulk-actions", TagController, :index_bulk_actions
      get "/tags/event-logs", TagController, :index_event_log_list
      get "/tags/event-logs/:id", TagController, :index_event_log_details

      resources "/tags", TagController do
        get "/event-logs", TagController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", TagController, :show_event_log_details, as: :event_log
      end

      # Teams

      post "/teams/bulk-actions", TeamController, :index_bulk_actions
      get "/teams/event-logs", TeamController, :index_event_log_list
      get "/teams/event-logs/:id", TeamController, :index_event_log_details

      resources "/teams", TeamController do
        get "/event-logs", TeamController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", TeamController, :show_event_log_details, as: :event_log
        resources "/members", TeamMemberController, as: "member"
      end

      # Users

      post "/users/bulk-actions", UserController, :index_bulk_actions
      get "/users/event-logs", UserController, :index_event_log_list
      get "/users/event-logs/:id", UserController, :index_event_log_details

      resources "/users", UserController do
        resources "/anonymization", UserAnonymizationController, as: "anonymization", only: [:create]
        resources "/impersonation", UserImpersonationController, as: "impersonation", only: [:create]
        get "/event-logs", UserController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", UserController, :show_event_log_details, as: :event_log
      end
    end
  end
end
