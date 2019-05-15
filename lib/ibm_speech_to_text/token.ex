defmodule IbmSpeechToText.Token do
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

  def retreive(api_key \\ System.get_env("SPEECH_TO_TEXT_IAM_APIKEY")) do
    with {:ok, conn} <-
           :gun.open(@auth_host, @auth_port, mk_conn_opts()),
         {:ok, :http} <- :gun.await_up(conn),
         stream_ref <- :gun.post(conn, @auth_endpoint, mk_headers(), mk_body(api_key)),
         {:response, _nofin, 200, _headers} <- :gun.await(conn, stream_ref),
         {:ok, response} <- :gun.await_body(conn, stream_ref),
         :ok <- :gun.flush(conn) do
      json = response |> Jason.decode!()

      %__MODULE__{
        token: json["access_token"],
        type: json["token_type"],
        expiration: json["expiration"],
        scope: json["scope"]
      }
    end
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

  @spec auth_header(__MODULE__.t()) :: {String.t(), iodata()}
  def auth_header(%__MODULE__{token: token, type: type}) do
    {"Authorization", "#{type} #{token}"}
  end
end
