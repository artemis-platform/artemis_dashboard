defmodule Ueberauth.Strategy.W3ID do
  @moduledoc """
  Provides an Ueberauth strategy for authenticating with W3ID.

  ### Setup

  Create an application in W3ID for you to use.

  Register a new application at: your w3id developer page and get the `client_id` and `client_secret`.

  Include the provider in your configuration for Ueberauth

      config :ueberauth, Ueberauth,
        providers: [
          w3id: { Ueberauth.Strategy.W3ID, [] }
        ]

  Then include the configuration for w3id.

      config :ueberauth, Ueberauth.Strategy.W3ID.OAuth,
        client_id: System.get_env("W3ID_CLIENT_ID"),
        client_secret: System.get_env("W3ID_CLIENT_SECRET")

  If you haven't already, create a pipeline and setup routes for your callback handler

      pipeline :auth do
        Ueberauth.plug "/auth"
      end
      scope "/auth" do
        pipe_through [:browser, :auth]
        get "/:provider/callback", AuthController, :callback
      end

  Create an endpoint for the callback where you will handle the `Ueberauth.Auth` struct

      defmodule MyApp.AuthController do
        use MyApp.Web, :controller
        def callback_phase(%{ assigns: %{ ueberauth_failure: fails } } = conn, _params) do
          # do things with the failure
        end
        def callback_phase(%{ assigns: %{ ueberauth_auth: auth } } = conn, params) do
          # do things with the auth
        end
      end

  You can edit the behaviour of the Strategy by including some options when you register your provider.
  To set the `uid_field`

      config :ueberauth, Ueberauth,
        providers: [
          w3id: { Ueberauth.Strategy.W3ID, [uid_field: :email] }
        ]

  Default is `:id`

  To set the default 'scopes' (permissions):

      config :ueberauth, Ueberauth,
        providers: [
          w3id: { Ueberauth.Strategy.W3ID, [default_scope: "openid"] }
        ]

  Default is empty ("") which "Grants read-only access to public information (includes public user profile info, public repository info, and gists)"
  """
  use Ueberauth.Strategy, uid_field: :id,
                          default_scope: "openid",
                          oauth2_module: Ueberauth.Strategy.W3ID.OAuth

  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Extra

  @doc """
  Handles the initial redirect to the w3id authentication page.
  To customize the scope (permissions) that are requested by w3id include them as part of your url:
      "/auth/w3id?scope=openid"
  You can also include a `state` param that w3id will return to you.
  """
  def handle_request!(conn) do
    scopes = conn.params["scope"] || option(conn, :default_scope)
    send_redirect_uri = Keyword.get(options(conn), :send_redirect_uri, true)

    opts =
      if send_redirect_uri do
        [redirect_uri: callback_url(conn), scope: scopes]
      else
        [scope: scopes]
      end

    opts =
      if conn.params["state"], do: Keyword.put(opts, :state, conn.params["state"]), else: opts

    module = option(conn, :oauth2_module)
    redirect!(conn, apply(module, :authorize_url!, [opts]))
  end

  @doc """
  Handles the callback from W3ID. When there is a failure from W3ID the failure is included in the
  `ueberauth_failure` struct. Otherwise the information returned from W3ID is returned in the `Ueberauth.Auth` struct.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    # module = option(conn, :oauth2_module)
    # token = apply(module, :get_token!, [[code: code]])

    # # TODO
    # IO.inspect "==="
    # IO.inspect "Handle Callback"
    # IO.inspect "---"
    # IO.inspect token
    # # IO.inspect token.access_token, limit: :infinity, printable_limit: :infinity

    # if token.access_token == nil do
    #   set_errors!(conn, [error(token.other_params["error"], token.other_params["error_description"])])
    # else
    #   fetch_user(conn, token)
    # end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc """
  Cleans up the private area of the connection used for passing the raw W3ID response around during the callback.
  """
  def handle_cleanup!(conn) do
    conn
    |> put_private(:w3id_user, nil)
    |> put_private(:w3id_token, nil)
  end

  @doc """
  Fetches the uid field from the W3ID response. This defaults to the option `uid_field` which in-turn defaults to `id`
  """
  def uid(conn) do
    conn |> option(:uid_field) |> to_string() |> fetch_uid(conn)
  end

  @doc """
  Includes the credentials from the W3ID response.
  """
  def credentials(conn) do
    token        = conn.private.w3id_token
    scope_string = (token.other_params["scope"] || "")
    scopes       = String.split(scope_string, ",")

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      expires_at: token.expires_at,
      token_type: token.token_type,
      expires: !!token.expires_at,
      scopes: scopes
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth` struct.
  """
  def info(conn) do
    # TODO
    IO.inspect "==="
    IO.inspect "info"
    IO.inspect "---"
    IO.inspect conn.private

    user = conn.private.w3id_user

    %Info{
      name: user["name"],
      description: user["bio"],
      nickname: user["login"],
      email: user["email"],
      location: user["location"],
      image: user["avatar_url"],
      urls: %{
        followers_url: user["followers_url"],
        avatar_url: user["avatar_url"],
        events_url: user["events_url"],
        starred_url: user["starred_url"],
        blog: user["blog"],
        subscriptions_url: user["subscriptions_url"],
        organizations_url: user["organizations_url"],
        gists_url: user["gists_url"],
        following_url: user["following_url"],
        api_url: user["url"],
        html_url: user["html_url"],
        received_events_url: user["received_events_url"],
        repos_url: user["repos_url"]
      }
    }
  end

  @doc """
  Stores the raw information (including the token) obtained from the W3ID callback.
  """
  def extra(conn) do
    %Extra {
      raw_info: %{
        token: conn.private.w3id_token,
        user: conn.private.w3id_user
      }
    }
  end

  defp fetch_uid(field, conn) do
    conn.private.w3id_user[field]
  end

  defp fetch_user(conn, token) do
    # TODO
    # IO.inspect "==="
    # IO.inspect "fetch_user"
    # IO.inspect "---"
    # IO.inspect conn
    # IO.inspect Ueberauth.Strategy.W3ID.OAuth.get(token, "")
    conn

    # conn = put_private(conn, :w3id_token, token)
    # case Ueberauth.Strategy.W3ID.OAuth.get(token, "/user") do
    #   {:ok, %OAuth2.Response{status_code: 401, body: _body}} ->
    #     set_errors!(conn, [error("token", "unauthorized")])
    #   {:ok, %OAuth2.Response{status_code: status_code, body: user}} when status_code in 200..399 ->
    #     case Ueberauth.Strategy.W3ID.OAuth.get(token, "/user/emails") do
    #       {:ok, %OAuth2.Response{status_code: status_code, body: emails}} when status_code in 200..399 ->
    #         user = Map.put user, "emails", emails
    #         put_private(conn, :w3id_user, user)
    #       {:error, _} -> # Continue on as before
    #         put_private(conn, :w3id_user, user)
    #     end
    #   {:error, %OAuth2.Error{reason: reason}} ->
    #     set_errors!(conn, [error("OAuth2", reason)])
    # end
  end

  defp option(conn, key) do
    Keyword.get(options(conn), key, Keyword.get(default_options(), key))
  end
end
