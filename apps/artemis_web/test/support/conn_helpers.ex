defmodule ArtemisWeb.ConnHelpers do
  alias ArtemisWeb.Mock

  def sign_in(conn, user \\ Mock.system_user()) do
    {:ok, token, _} = ArtemisWeb.Guardian.encode_and_sign(user, %{}, token_type: :access)

    Plug.Conn.put_req_header(conn, "authorization", "bearer: " <> token)
  end

  def sign_in_with_client_credentials(conn, user \\ Mock.system_user()) do
    basic = Base.encode64("#{user.client_key}:#{user.client_secret}")

    Plug.Conn.put_req_header(conn, "authorization", "basic: " <> basic)
  end

  @doc """
  Disable a feature by slug. Will update an existing feature or create a new one.
  """
  def disable_feature(slug), do: Artemis.DataCase.disable_feature(slug)

  @doc """
  Enable a feature by slug. Will update an existing feature or create a new one.
  """
  def enable_feature(slug), do: Artemis.DataCase.enable_feature(slug)
end
