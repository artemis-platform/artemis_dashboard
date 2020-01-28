defmodule ArtemisWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use ArtemisWeb, :controller
      use ArtemisWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: ArtemisWeb

      import Plug.Conn
      import Phoenix.LiveView.Controller, only: [live_render: 3]
      import ArtemisWeb.Gettext
      import ArtemisWeb.Guardian.Helpers
      import ArtemisWeb.Helpers.Controller
      import ArtemisWeb.UserAccess

      alias ArtemisWeb.Router.Helpers, as: Routes

      defp render_format(conn, filename, params) do
        format = get_format(conn)
        conn = render_format_headers(conn, format)

        render(conn, "#{filename}.#{format}", params)
      end

      defp render_format_headers(conn, "csv"), do: render_format_headers(conn, :csv)

      defp render_format_headers(conn, :csv) do
        filename = Regex.replace(~r/[^a-z0-9_-]+/, conn.request_path, "")

        conn
        |> put_resp_header("content-disposition", "attachment; filename=#{filename}.csv")
        |> put_resp_content_type("text/csv")
      end

      defp render_format_headers(conn, _), do: conn

      # User Permissions

      defp authorize(conn, permission, render_controller) do
        case has?(conn, permission) do
          true -> render_controller.()
          false -> render_forbidden(conn)
        end
      end

      defp authorize_any(conn, permissions, render_controller) do
        case has_any?(conn, permissions) do
          true -> render_controller.()
          false -> render_forbidden(conn)
        end
      end

      defp authorize_all(conn, permissions, render_controller) do
        case has_all?(conn, permissions) do
          true -> render_controller.()
          false -> render_forbidden(conn)
        end
      end

      # Features

      defp feature_active?(conn, feature, render_controller) do
        case Artemis.Helpers.Feature.active?(feature) do
          true -> render_controller.()
          false -> render_forbidden(conn)
        end
      end

      defp feature_active_any?(conn, features, render_controller) do
        case Enum.any?(features, &Artemis.Helpers.Feature.active?(&1)) do
          true -> render_controller.()
          false -> render_forbidden(conn)
        end
      end

      defp feature_active_all?(conn, features, render_controller) do
        case Enum.all?(features, &Artemis.Helpers.Feature.active?(&1)) do
          true -> render_controller.()
          false -> render_forbidden(conn)
        end
      end

      @doc """
      Return a 404 not found page
      """
      def render_not_found(conn) do
        conn
        |> put_status(404)
        |> put_view(ArtemisWeb.ErrorView)
        |> render("404.html", error_page: true)
      end
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/artemis_web/templates",
        namespace: ArtemisWeb,
        pattern: "**/*"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]
      import Phoenix.LiveView, only: [live_render: 2, live_render: 3, live_link: 1, live_link: 2]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import ArtemisWeb.Gettext
      import ArtemisWeb.Guardian.Helpers
      import ArtemisWeb.UserAccess
      import ArtemisWeb.ViewHelper.Breadcrumbs
      import ArtemisWeb.ViewHelper.BulkActions
      import ArtemisWeb.ViewHelper.Cache
      import ArtemisWeb.ViewHelper.Charts
      import ArtemisWeb.ViewHelper.Conditionals
      import ArtemisWeb.ViewHelper.Errors
      import ArtemisWeb.ViewHelper.Events
      import ArtemisWeb.ViewHelper.Export
      import ArtemisWeb.ViewHelper.Filter
      import ArtemisWeb.ViewHelper.Form
      import ArtemisWeb.ViewHelper.HTML
      import ArtemisWeb.ViewHelper.Navigation
      import ArtemisWeb.ViewHelper.Notifications
      import ArtemisWeb.ViewHelper.Numbers
      import ArtemisWeb.ViewHelper.OnCall
      import ArtemisWeb.ViewHelper.Pagination
      import ArtemisWeb.ViewHelper.Presence
      import ArtemisWeb.ViewHelper.Print
      import ArtemisWeb.ViewHelper.QueryParams
      import ArtemisWeb.ViewHelper.Search
      import ArtemisWeb.ViewHelper.Tables
      import ArtemisWeb.ViewHelper.User
      import ArtemisWeb.ViewHelper.Values

      alias ArtemisWeb.Router.Helpers, as: Routes
      alias ArtemisWeb.ViewHelper.BulkActions.BulkAction
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import ArtemisWeb.Gettext
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
