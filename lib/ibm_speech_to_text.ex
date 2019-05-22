defmodule IBMSpeechToText do
  @type region :: :dallas | :frankfurt | :london | :sydney | :tokyo | :washington

  @api_host_name_map %{
    dallas: 'stream.watsonplatform.net',
    frankfurt: 'stream-fra.watsonplatform.net',
    sydney: 'gateway-syd.watsonplatform.net',
    washington: 'gateway-wdc.watsonplatform.net',
    tokyo: 'gateway-tok.watsonplatform.net',
    london: 'gateway-lon.watsonplatform.net'
  }

  @doc """
  Provides API host name for the specific region
  """
  @spec api_host_name(region()) :: {:ok, charlist()} | {:error, {:invalid_region, any()}}
  def api_host_name(region) do
    case @api_host_name_map[region] do
      nil -> {:error, {:invalid_region, region}}
      api_host -> {:ok, api_host}
    end
  end
end
