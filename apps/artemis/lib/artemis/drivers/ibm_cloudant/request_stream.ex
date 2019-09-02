defmodule Artemis.Drivers.IBMCloudant.RequestStream do
  require Logger

  alias Artemis.Drivers.IBMCloudant

  defmodule CloudantError do
    defexception message: "IBM Cloudant Error"
  end

  @doc """
  Wraps the Mint.HTTP.request/5 function.
  """
  def call(params) do
    {:ok, conn} = get_connection(params)

    get_request(conn, params)
  end

  def call!(params) do
    case call(params) do
      {:error, message} -> raise(CloudantError, message)
      {:ok, result} -> result
    end
  end

  # Helpers

  defp get_connection(%{host: host}) do
    host_config= IBMCloudant.Config.get_host_config_by!(name: host)
    hostname = host_config[:hostname]
    protocol = String.to_atom(host_config[:protocol])
    port = Artemis.Helpers.to_integer(host_config[:port])

    Mint.HTTP.connect(protocol, hostname, port, timeout: :infinity)
  end

  defp get_request(conn, params) do
    path = params[:path]
    method = params[:method]
    headers = get_request_headers(params)

    Mint.HTTP.request(conn, method, path, headers, :stream)
  end

  defp get_request_headers(%{host: host} = params) do
    host_config = IBMCloudant.Config.get_host_config_by!(name: host)

    add_authorization_header(host_config, params)
  end

  defp add_authorization_header(host_config, params) do
    default_headers = [
      {"Accept", "application/json"},
      {"Content-Type", "application/json"}
    ]

    passed_headers = Map.get(params, :headers, [])
    headers = Keyword.merge(default_headers, passed_headers)

    case host_config[:auth_type] do
      "ibm_cloud_iam" -> add_ibm_cloud_iam_authorization_header(host_config, headers)
      "basic" -> add_basic_authorization_header(host_config, headers)
      _ -> headers
    end
  end

  defp add_ibm_cloud_iam_authorization_header(host_config, headers) do
    key = Keyword.fetch!(host_config, :ibm_cloud_iam_api_key)
    token = Artemis.Worker.IBMCloudIAMAccessToken.get_token!(key)

    [{"Authorization", "Bearer #{token}"}] ++ headers
  end

  defp add_basic_authorization_header(config, headers) do
    username = Keyword.fetch!(config, :username)
    password = Keyword.fetch!(config, :password)
    data = "#{username}:#{password}"
    encoded = Base.encode64(data)

    [{"Authorization", "Basic #{encoded}"}] ++ headers
  end
end
