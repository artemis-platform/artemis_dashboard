defmodule ArtemisWeb.Router do
  use ArtemisWeb, :router

  require Ueberauth

  pipeline :browser do
    plug :accepts, ["html", "csv"]
    plug :fetch_session
    plug :fetch_flash
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

      resources "/docs", WikiPageController do
        resources "/comments", WikiPageCommentController, only: [:create, :edit, :update, :delete], name: :comment
        resources "/revisions", WikiRevisionController, only: [:index, :show, :delete], as: :revision
        put "/tags", WikiPageTagController, :update, as: :tag
      end

      get "/docs/:id/:slug", WikiPageController, :show
      resources "/event-logs", EventLogController, only: [:index, :show]
      resources "/features", FeatureController

      resources "/incidents", IncidentController, only: [:index, :show, :delete] do
        resources "/comments", IncidentCommentController, only: [:create, :edit, :update, :delete], name: :comment
        put "/tags", IncidentTagController, :update, as: :tag
      end

      resources "/permissions", PermissionController
      resources "/roles", RoleController
      resources "/search", SearchController, only: [:index]
      resources "/tags", TagController

      resources "/users", UserController do
        resources "/impersonation", UserImpersonationController, as: "impersonation", only: [:create]
      end
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", ArtemisWeb do
  #   pipe_through :api
  # end
end
