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
      import Phoenix.LiveView.Controller
      import ArtemisWeb.Gettext
      import ArtemisWeb.Guardian.Helpers
      import ArtemisWeb.Helpers.Controller
      import ArtemisWeb.UserAccess

      alias ArtemisWeb.Router.Helpers, as: Routes

      # Render with cache then update asynchronously

      defp render_with_cache_then_update(conn, params, view_module, filename, async_data, options \\ []) do
        options =
          options
          |> Keyword.put_new(:async_data, async_data)
          |> Keyword.put_new(:async_fetch?, !Artemis.Helpers.empty?(params))
          |> Keyword.put_new(:async_status_after_initial_render, :reloading)

        render_async(conn, view_module, filename, options)
      end

      # Render asynchronously

      defp render_async(conn, view_module, filename, options \\ []) do
        format = get_format(conn)
        async_data = Keyword.get(options, :async_data)
        async_status_after_initial_render = Keyword.get(options, :async_status_after_initial_render, :loading)
        template = "#{filename}.#{format}"

        assigns =
          options
          |> Keyword.get(:assigns, [])
          |> Artemis.Helpers.keys_to_atoms()
          |> Enum.into([])
          |> Keyword.put_new(:query_params, conn.query_params)
          |> Keyword.put_new(:request_path, conn.request_path)
          |> Keyword.put_new(:user, current_user(conn))

        session =
          assigns
          |> Keyword.put(:async_data, async_data)
          |> Keyword.put(:async_data_reload_limit, Keyword.get(options, :async_data_reload_limit, 1))
          |> Keyword.put(:async_fetch?, Keyword.get(options, :async_fetch?, true))
          |> Keyword.put(:async_render_type, :page)
          |> Keyword.put(:async_status_after_initial_render, async_status_after_initial_render)
          |> Keyword.put(:view_module, view_module)
          |> ArtemisWeb.ViewHelper.Async.async_convert_assigns_to_session(template)

        case format do
          "html" ->
            Phoenix.LiveView.Controller.live_render(conn, ArtemisWeb.AsyncRenderLive, session: session)

          _ ->
            assigns = Keyword.put(assigns, :async_data, async_data.(self(), assigns))

            render_format(conn, filename, assigns)
        end
      end

      # Render Format

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
      import Phoenix.LiveView.Helpers

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import ArtemisWeb.Gettext
      import ArtemisWeb.Guardian.Helpers
      import ArtemisWeb.UserAccess
      import ArtemisWeb.ViewHelper.Async
      import ArtemisWeb.ViewHelper.Breadcrumbs
      import ArtemisWeb.ViewHelper.BulkActions
      import ArtemisWeb.ViewHelper.Cache
      import ArtemisWeb.ViewHelper.Charts
      import ArtemisWeb.ViewHelper.Colors
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
      import ArtemisWeb.ViewHelper.Routes
      import ArtemisWeb.ViewHelper.Schedule
      import ArtemisWeb.ViewHelper.Search
      import ArtemisWeb.ViewHelper.Status
      import ArtemisWeb.ViewHelper.Tables
      import ArtemisWeb.ViewHelper.User
      import ArtemisWeb.ViewHelper.Values

      alias ArtemisWeb.Router.Helpers, as: Routes
      alias ArtemisWeb.ViewHelper.BulkActions.BulkAction

      # Delay the rendering of `do` blocks through macros

      defmacro render_and_benchmark(options \\ [], do: block) do
        quote do
          key = Keyword.get(unquote(options), :key, "Render Benchmark")

          Artemis.Helpers.benchmark(key, fn ->
            raw(unquote(block))
          end)
        end
      end

      defmacro render_from_cache_then_update(name, user, do: block) do
        quote do
          callback = fn -> unquote(block) end

          unquote(name)
          |> ArtemisWeb.RenderCache.call_with_cache_then_update(callback, unquote(user))
          |> Map.get(:data)
          |> raw()
        end
      end

      defmacro async_render_when_loaded(assigns, options \\ [], do: block) do
        quote do
          status = unquote(assigns)[:async_status]
          loading_icon? = Keyword.get(unquote(options), :loading_icon, true)
          reloading_icon? = Keyword.get(unquote(options), :reloading_icon, true)

          cond do
            status == :loading && loading_icon? ->
              Phoenix.HTML.Tag.content_tag(:div, "", class: "ui active centered inline loader")

            true ->
              raw(unquote(block))
          end
        end
      end
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
