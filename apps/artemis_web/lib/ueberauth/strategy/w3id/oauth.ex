defmodule Ueberauth.Strategy.W3ID.OAuth do
  @moduledoc """
  An implementation of OAuth2 for W3ID.
  To add your `client_id` and `client_secret` include these values in your configuration.
      config :ueberauth, Ueberauth.Strategy.W3ID.OAuth,
        client_id: System.get_env("UEBERAUTH_W3ID_CLIENT_ID"),
        client_secret: System.get_env("UEBERAUTH_W3ID_CLIENT_SECRET")
        token_url: System.get_env("UEBERAUTH_W3ID_TOKEN_URL"),
        authorize_url: System.get_env("UEBERAUTH_W3ID_AUTHORIZE_URL")
  """
  use OAuth2.Strategy

  def defaults(),
    do: [
      strategy: __MODULE__,
      authorize_url: "https://w3id.sso.ibm.com/isam/oidc/endpoint/amapp-runtime-oidcidp/authorize",
      token_url: "https://w3id.sso.ibm.com/isam/oidc/endpoint/amapp-runtime-oidcidp/token",
      response_type: "token"
    ]

  @doc """
  Construct a client for requests to W3ID.
  Optionally include any OAuth2 options here to be merged with the defaults.
      Ueberauth.Strategy.W3ID.OAuth.client(redirect_uri: "http://localhost:4000/auth/w3id/callback")
  This will be setup automatically for you in `Ueberauth.Strategy.W3ID`.
  These options are only useful for usage outside the normal callback phase of Ueberauth.
  """
  def client(opts \\ []) do
    config =
      :ueberauth
      |> Application.fetch_env!(Ueberauth.Strategy.W3ID.OAuth)
      |> check_config_key_exists(:client_id)
      |> check_config_key_exists(:client_secret)

    client_opts =
      defaults()
      |> Keyword.merge(config)
      |> Keyword.merge(opts)

    OAuth2.Client.new(client_opts)
  end

  @doc """
  Provides the authorize url for the request phase of Ueberauth. No need to call this usually.
  """
  def authorize_url!(params \\ [], opts \\ []) do
    opts
    |> client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get(token, url \\ "", headers \\ [], opts \\ []) do
    [token: token]
    |> client
    |> put_param("client_secret", client().client_secret)
    |> OAuth2.Client.get(url, headers, opts)
  end

  def get_token!(params \\ [], options \\ []) do
    headers        = Keyword.get(options, :headers, [])
    options        = Keyword.get(options, :options, [])
    client_options = Keyword.get(options, :client_options, [])
    client         = OAuth2.Client.get_token!(client(client_options), params, headers, options)
    client.token
  end

  # Strategy Callbacks

  def authorize_url(client, params) do
    OAuth2.Strategy.AuthCode.authorize_url(client, params)
  end

  def get_token(client, params, headers) do
    client
    |> put_param("client_secret", client.client_secret)
    |> put_header("Accept", "application/json")
    |> OAuth2.Strategy.AuthCode.get_token(params, headers)
  end

  defp check_config_key_exists(config, key) when is_list(config) do
    unless Keyword.has_key?(config, key) do
      raise "#{inspect (key)} missing from config :ueberauth, Ueberauth.Strategy.W3ID"
    end
    config
  end
  defp check_config_key_exists(_, _) do
    raise "Config :ueberauth, Ueberauth.Strategy.W3ID is not a keyword list, as expected"
  end
end
