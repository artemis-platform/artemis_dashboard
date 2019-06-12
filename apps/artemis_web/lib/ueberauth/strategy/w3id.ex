defmodule Ueberauth.Strategy.W3ID do
  use Ueberauth.Strategy

  # Authorize Phase

  @doc """
  The initial redirect to the w3id authentication page.
  """
  def handle_request!(conn) do
    authorize_url = Ueberauth.Strategy.W3ID.OAuth.authorize_url!()

    redirect!(conn, authorize_url)
  end

  # Callback Phase

  @doc """
  The callback phase exchanges the code for a valid token.

  In addition to the standard token information, W3ID also returns an
  `id_token` JWT which contains user data. This can be used instead of the
  standard call to an OAuth2 access token introspection endpoint.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    response = Ueberauth.Strategy.W3ID.OAuth.get_token!(code: code)

    parse_callback_response(conn, response)
  end

  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  defp parse_callback_response(conn, %{token: data}) do
    parse_callback_token(conn, data)
  end

  defp parse_callback_response(conn, _) do
    set_errors!(conn, ["missing_token", "Server response did not include token"])
  end

  defp parse_callback_token(conn, %{other_params: %{"id_token" => id_token}} = token) do
    user = parse_id_token(id_token)

    conn
    |> put_private(:w3id_token, token)
    |> put_private(:w3id_user, user)
  end

  defp parse_callback_token(conn, %{access_token: error}) do
    set_errors!(conn, ["missing_id_token_jwt", error])
  end

  defp parse_callback_token(conn, _) do
    set_errors!(conn, ["missing_id_token_jwt", "Server response did not include id_token jwt"])
  end

  # Callback Phase - Struct Helpers

  def credentials(conn) do
    token = conn.private.w3id_token
    scope_string = (token.other_params["scope"] || "")
    scopes = String.split(scope_string, ",")

    %Ueberauth.Auth.Credentials{
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      other: token.other_params,
      refresh_token: token.refresh_token,
      scopes: scopes,
      token: token.access_token,
      token_type: token.token_type
    }
  end

  def extra(conn) do
    %Ueberauth.Auth.Extra{
      raw_info: %{
        id_token_data: conn.private.w3id_user
      }
    }
  end

  def info(conn) do
    data = conn.private.w3id_user

    %Ueberauth.Auth.Info{
      email: data["emailAddress"],
      first_name: data["firstName"],
      last_name: data["lastName"],
      name: URI.decode(data["cn"])
    }
  end

  def uid(conn), do: conn.private.w3id_user["uid"]

  # Cleanup Phase

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:w3id_token, nil)
    |> put_private(:w3id_user, nil)
  end

  # Helpers

  defp parse_id_token(id_token) do
    id_token
    |> String.split(".")
    |> Enum.at(1)
    |> Base.url_decode64!(padding: false)
    |> Jason.decode!
  end
end
