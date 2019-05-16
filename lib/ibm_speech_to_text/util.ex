defmodule IBMSpeechToText.Util do
  @moduledoc false

  @spec ssl_connection_opts(:gun.opts()) :: :gun.opts()
  def ssl_connection_opts(opts \\ %{}) do
    %{
      transport: :ssl,
      protocols: [:http],
      transport_opts: [cacerts: :certifi.cacerts()]
    }
    |> Map.merge(opts)
  end

  @spec ssl_port() :: 443
  def ssl_port(), do: 443
end
