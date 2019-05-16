defmodule IBMSpeechToText.Token do
  @moduledoc """
  This module provides a way to get IAM tokens used for authenticated requests
  to IBM Cloud Services
  """

  @type t() :: %__MODULE__{
          token: String.t(),
          type: String.t(),
          expiration: non_neg_integer(),
          scope: String.t()
        }
  defstruct [:token, :type, :expiration, :scope]

  @auth_host 'iam.bluemix.net'
  @auth_port 443
  @auth_endpoint "/identity/token"

  @doc """
  Gets access token for the given IAM API key

  If the API key is not provided, it is taken from environment variable
  `SPEECH_TO_TEXT_IAM_APIKEY`

  More info on tokens and authentication can be found [here](https://cloud.ibm.com/docs/services/watson?topic=watson-iam)
  """
  @spec get(api_key :: String.t()) :: {:ok, __MODULE__.t()} | {:error, reason}
        when reason:
               :timeout
               | {:unexpected_trailers, any}
               | {:unknown_response, any}
               | {:response, Keyword.t()}
               | any
  def get(api_key \\ System.get_env("SPEECH_TO_TEXT_IAM_APIKEY")) do
    with {:ok, conn} <- :gun.open(@auth_host, @auth_port, mk_conn_opts()),
         {:ok, _protocol} <- :gun.await_up(conn) do
      result = send_request(conn, api_key)
      :gun.close(conn)
      :gun.flush(conn)
      result
    end
  end

  defp send_request(conn, api_key) do
    stream_ref = :gun.post(conn, @auth_endpoint, mk_headers(), mk_body(api_key))

    case :gun.await(conn, stream_ref) do
      {:response, :nofin, status, _headers} ->
        body = :gun.await_body(conn, stream_ref)
        handle_body(body, status)

      {:error, _} = e ->
        e

      result ->
        {:error, {:unknown_response, result}}
    end
  end

  defp handle_body({:error, _} = e, _), do: e
  defp handle_body({:ok, _body, trailers}, _), do: {:error, {:unexpected_trailers, trailers}}

  defp handle_body({:ok, body}, 200) do
    json = body |> Jason.decode!()

    {:ok,
     %__MODULE__{
       token: json["access_token"],
       type: json["token_type"],
       expiration: json["expiration"],
       scope: json["scope"]
     }}
  end

  defp handle_body({:ok, body}, status) do
    json = body |> Jason.decode!()

    {:error, {:response, status: status, message: json["errorMessage"], code: json["errorCode"]}}
  end

  defp mk_conn_opts() do
    %{
      transport: :ssl,
      protocols: [:http],
      transport_opts: [cacerts: :certifi.cacerts()]
    }
  end

  defp mk_headers() do
    [
      {"Content-Type", "application/x-www-form-urlencoded"},
      {"Accept", "application/json"}
    ]
  end

  defp mk_body(api_key) do
    URI.encode_query(grant_type: "urn:ibm:params:oauth:grant-type:apikey", apikey: api_key)
  end

  @doc """
  Creates "Authorization" header using token that can be used when making requests
  to IBM Cloud Service API
  """
  @spec auth_header(__MODULE__.t()) :: {String.t(), iodata()}
  def auth_header(%__MODULE__{token: token, type: type}) do
    {"Authorization", "#{type} #{token}"}
  end
end
