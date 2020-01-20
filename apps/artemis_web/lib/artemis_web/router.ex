defmodule ArtemisWeb.Router do
  use ArtemisWeb, :router

  require Ueberauth

  pipeline :browser do
    plug :accepts, ["html", "csv"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
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

      # Customers

      post "/customers/bulk-actions", CustomerController, :index_bulk_actions
      get "/customers/event-logs", CustomerController, :index_event_log_list
      get "/customers/event-logs/:id", CustomerController, :index_event_log_details

      resources "/customers", CustomerController do
        get "/event-logs", CustomerController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", CustomerController, :show_event_log_details, as: :event_log
      end

      # Docs

      resources "/docs", WikiPageController do
        resources "/comments", WikiPageCommentController, only: [:create, :edit, :update, :delete], name: :comment
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
        resources "/comments", IncidentCommentController, only: [:create, :edit, :update, :delete], name: :comment
        put "/tags", IncidentTagController, :update, as: :tag
      end

      # Jobs

      post "/jobs/bulk-actions", JobController, :index_bulk_actions
      get "/jobs/event-logs", JobController, :index_event_log_list
      get "/jobs/event-logs/:id", JobController, :index_event_log_details

      resources "/jobs", JobController do
        get "/event-logs", JobController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", JobController, :show_event_log_details, as: :event_log
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

      # Tags

      post "/tags/bulk-actions", TagController, :index_bulk_actions
      get "/tags/event-logs", TagController, :index_event_log_list
      get "/tags/event-logs/:id", TagController, :index_event_log_details

      resources "/tags", TagController do
        get "/event-logs", TagController, :show_event_log_list, as: :event_log
        get "/event-logs/:id", TagController, :show_event_log_details, as: :event_log
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
