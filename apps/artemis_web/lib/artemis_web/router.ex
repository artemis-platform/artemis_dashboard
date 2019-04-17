defmodule ArtemisWeb.Router do
  use ArtemisWeb, :router

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

    get "/", HomeController, :index
    resources "/sessions", SessionController, only: [:new, :show, :delete]

    scope "/" do
      pipe_through :require_auth

      resources "/docs", WikiPageController do
        resources "/comments", WikiPageCommentController, only: [:create, :edit, :update, :delete], name: :comment
        resources "/revisions", WikiRevisionController, only: [:index, :show, :delete], as: :revision
      end
      get "/docs/:id/:slug", WikiPageController, :show
      resources "/event-logs", EventLogController, only: [:index, :show]
      resources "/features", FeatureController
      resources "/permissions", PermissionController
      resources "/roles", RoleController
      resources "/help", HelpController, only: [:index]
      resources "/search", SearchController, only: [:index]
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
