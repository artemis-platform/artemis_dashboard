defmodule Ueberauth.Strategy.W3ID.OAuth do
  use OAuth2.Strategy

  require Base
  require Logger

  def defaults(),
    do: [
      strategy: __MODULE__,
      authorize_url: "https://w3id.sso.ibm.com/isam/oidc/endpoint/amapp-runtime-oidcidp/authorize",
      token_url: "https://w3id.sso.ibm.com/isam/oidc/endpoint/amapp-runtime-oidcidp/token",
      response_type: "token"
    ]

  def client(options \\ []) do
    config = Application.fetch_env!(:ueberauth, Ueberauth.Strategy.W3ID.OAuth)

    client_options =
      defaults()
      |> Keyword.merge(config)
      |> Keyword.merge(options)

    OAuth2.Client.new(client_options)
  end

  # Authorize Phase

  def authorize_url!(options \\ []) do
    params = Keyword.put(options, :scope, "openid")

    OAuth2.Client.authorize_url!(client(), params)
  end

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  # Callback Phase

  def get_token!(params \\ [], headers \\ [], opts \\ []) do
    OAuth2.Client.get_token!(client(), params, headers, opts)
  end

  def get_token(client, params, headers) do
    client
    |> put_param(:client_secret, client.client_secret)
    |> put_header("accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end
end
