defmodule Artemis.DemoUser do
  @moduledoc """
  Self-contained module for demo user creation and auto-login.

  When `Application.get_env(:artemis, :demo_user_enabled, true)` (the default), this module:

  1. Seeds a demo user on application start (via `ensure_created/0`)
  2. Provides a Plug (`Artemis.DemoUser.Plug`) that auto-logs in
     unauthenticated visitors as the demo user

  To disable, set `ARTEMIS_DEMO_USER_ENABLED=false` in your environment.
  This module does nothing when disabled — no user is created, no auto-login occurs.
  """

  alias Artemis.Accounts
  alias Artemis.Accounts.User
  alias Artemis.Repo

  @email "demo@artemis.local"
  @password "demo_password_123"

  @doc """
  Returns true if the demo user feature is enabled.
  """
  def enabled? do
    Application.get_env(:artemis, :demo_user_enabled, true)
  end

  @doc """
  Returns the demo user email.
  """
  def email, do: @email

  @doc """
  Ensures the demo user exists in the database. Idempotent — safe to call
  multiple times (e.g., in seeds or application start).

  Returns `{:ok, user}` or `{:error, reason}`.
  """
  def ensure_created do
    if enabled?() do
      case Accounts.get_user_by_email(@email) do
        %User{} = user ->
          {:ok, user}

        nil ->
          %User{}
          |> User.email_changeset(%{email: @email})
          |> User.password_changeset(%{password: @password})
          |> Ecto.Changeset.put_change(:confirmed_at, DateTime.utc_now(:second))
          |> Repo.insert()
      end
    else
      {:ok, :disabled}
    end
  end

  @doc """
  Returns the demo user if it exists, nil otherwise.
  """
  def get_user do
    Accounts.get_user_by_email(@email)
  end

  # ------------------------------------------------------------------
  # Plug — auto-login unauthenticated visitors as the demo user
  # ------------------------------------------------------------------

  defmodule Plug do
    @moduledoc false
    @behaviour Elixir.Plug

    import Elixir.Plug.Conn

    alias Artemis.Accounts
    alias Artemis.DemoUser

    @impl true
    def init(opts), do: opts

    @impl true
    def call(conn, _opts) do
      if DemoUser.enabled?() && !logged_in?(conn) do
        case DemoUser.get_user() do
          nil -> conn
          user -> log_in_demo_user(conn, user)
        end
      else
        conn
      end
    end

    defp logged_in?(conn) do
      get_session(conn, :user_token) != nil
    end

    defp log_in_demo_user(conn, user) do
      token = Accounts.generate_user_session_token(user)

      conn
      |> put_session(:user_token, token)
      |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
      |> assign(:current_scope, Artemis.Accounts.Scope.for_user(user))
    end
  end
end
