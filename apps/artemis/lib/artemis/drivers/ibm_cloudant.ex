defmodule Artemis.Drivers.IBMCloudant do
  use HTTPoison.Base

  require Logger

  defmodule CloudantError do
    defexception message: "IBM Cloudant Error"
  end

  @doc """
  Wraps the HTTPoison.request/1 function.

  # Params

  Takes two additional params in addition to the default `HTTPoison.Request` keys:

  - `host`
  - `path`

  These can be used as an alternative to `url`. The driver can be used to connect to
  multiple Cloudant databases, each using different hostnames and
  authentication strategies.

  These per-host values are defined in the application config. The `host` value
  should be a an atom, corresponding to the key in the config. When passed, the driver
  will lookup the information in the config and create the correct URL and Headers.

  All other params through to `HTTPoison.Request`.

  # Config

  Cloudant configuration in `config/config.ex` should take the following shape:

    config :artemis, :ibm_cloudant,
      hosts: [
        [
          name: :shared,
          auth_type: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_AUTH_TYPE"),
          username: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_USERNAME"),
          password: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_PASSWORD"),
          hostname: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_HOSTNAME"),
          search_enabled: System.get_env("ARTEMIS_IBM_CLOUDANT_SHARED_SEARCH_ENABLED") == "true",
          search_design_doc: "text-search",
          search_index: "text-search-index"
        ]
      ],
      databases: [
        [
          host: :shared,
          name: "jobs",
          schema: Artemis.SharedJob
        ]
      ]

  Where each `databases` value includes a `host: ` value that corresponds with
  a `name: ` field in an entry under the `hosts key.

  NOTICE: each `schema` that uses Cloudant must have a corresponding entry in the
  `databases` section of the config.

  # Response

  Params are passed to `HTTPoison.request` and returns either:

    {:ok, body}
    {:error, message}

  Where on success `body` is the decoded response body, and on failure `message` is either
  the HTTPoison error message or the response body when a 400/500 status code is received.
  """
  def call(params) do
    request_params = get_request_params(params)

    struct(HTTPoison.Request, request_params)
    |> request()
    |> simplified_response()
  end

  def call!(params) do
    case call(params) do
      {:error, message} -> raise(CloudantError, message)
      {:ok, result} -> result
    end
  end

  # Callbacks

  def process_request_headers(headers) do
    [
      Accept: "application/json",
      "Content-Type": "application/json"
    ] ++ headers
  end

  def process_request_url(url) do
    case includes_protocol?(url) do
      true -> url
      false -> "https://#{url}"
    end
  end

  def process_response_body(body) do
    Jason.decode!(body)
  rescue
    _ -> body
  end

  # Helpers

  defp get_request_params(%{host: host, path: path} = params) do
    host_config = get_cloudant_host_config!(host)
    headers = add_authorization_header(host_config, params)
    url = "#{host_config[:hostname]}/#{path}"

    params
    |> Map.delete(:host)
    |> Map.delete(:path)
    |> Map.put(:headers, headers)
    |> Map.put(:url, url)
  end

  defp get_request_params(%{path: _}), do: raise "Must specify `host` when using `path` param"

  defp get_request_params(params), do: params

  defp add_authorization_header(host_config, params) do
    headers = Map.get(params, :headers, [])

    case host_config[:auth_type] do
      "ibm_cloud_iam" -> add_ibm_cloud_iam_authorization_header(host_config, headers)
      _ -> add_basic_authorization_header(host_config, headers)
    end
  end

  defp add_ibm_cloud_iam_authorization_header(_host_config, headers) do
    token = Artemis.Worker.IBMCloudIAMAccessToken.get_token!()

    [Authorization: "Bearer #{token}"] ++ headers
  end

  defp add_basic_authorization_header(config, headers) do
    username = Keyword.fetch!(config, :username)
    password = Keyword.fetch!(config, :password)
    data = "#{username}:#{password}"
    encoded = Base.encode64(data)

    [Authorization: "Basic #{encoded}"] ++ headers
  end

  defp includes_protocol?(url) when is_bitstring(url), do: String.contains?(url, "://")
  defp includes_protocol?(_), do: false

  defp simplified_response({:ok, %HTTPoison.AsyncResponse{} = async_response}) do
    {:ok, async_response}
  end

  defp simplified_response({:ok, %{body: body, status_code: status_code}}) when status_code in 200..399 do
    {:ok, body}
  end

  defp simplified_response({:ok, %{body: body, status_code: status_code} = request}) when status_code in 400..599 do
    Logger.debug("Error response for Cloudant HTTP request: " <> inspect(request))

    {:error, body}
  end

  defp simplified_response(error) do
    Logger.info("Error response for Cloudant HTTP request: " <> inspect(error))

    error
  end

  defp get_cloudant_host_config!(host) do
    :artemis
    |> Application.fetch_env!(:ibm_cloudant)
    |> Keyword.fetch!(:hosts)
    |> Enum.find(&Keyword.get(&1, :name) == host)
  end
end
