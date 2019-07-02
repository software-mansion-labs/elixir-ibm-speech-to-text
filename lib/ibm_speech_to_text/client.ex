defmodule IBMSpeechToText.Client do
  @moduledoc """
  A client process responsible for communication with Speech to Text API
  """
  use GenServer
  alias IBMSpeechToText.{Token, Util, Response}
  alias IBMSpeechToText.Message.{Start, Stop}

  @endpoint_path "/speech-to-text/api/v1/recognize"

  @doc """
  Starts a client process responsible for communication with Speech to Text API
  linked to the current process.

  Requires API url or region atom (See `t:IBMSpeechToText.region/0`) and
  an API key used to obtain `IBMSpeechToText.Token` ([here](https://cloud.ibm.com/docs/services/watson?topic=watson-iam) you can learn how to get it)

  ## Options

  * `:stream_to` - pid of the process that will receive recognition results, defaults to the caller of `start_link/3`
  * `:keep_alive` - if set to true, the client will automatically reconnect to the API after timeout (IBM API will close the connection after 30 seconds of silence or no data). False by default.
  * Recognition parameters (such as `:model`) described in [IBM Cloud docs](https://cloud.ibm.com/apidocs/speech-to-text#WSRecognizeMethod)

  ## Example

  ```
  #{inspect(__MODULE__)}.start_link(
    :frankfurt,
    "ABCDEFGHIJKLMNO",
    model: "en-GB_BroadbandModel"
  )
  ```
  """
  @spec start_link(IBMSpeechToText.region() | charlist(), String.t(), Keyword.t()) ::
          :ignore | {:error, any()} | {:ok, pid()}
  def start_link(api_region_or_url, api_key, opts \\ []) do
    do_start(:start_link, api_region_or_url, api_key, opts)
  end

  @doc """
  Starts a client process without links.

  See `start_link/3` for more info.
  """
  @spec start(IBMSpeechToText.region() | charlist(), String.t(), Keyword.t()) ::
          :ignore | {:error, any()} | {:ok, pid()}
  def start(api_region_or_url, api_key, opts \\ []) do
    do_start(:start, api_region_or_url, api_key, opts)
  end

  defp do_start(function, region, api_key, opts) when is_atom(region) do
    with {:ok, api_url} <- IBMSpeechToText.api_host_name(region) do
      do_start(function, api_url, api_key, opts)
    end
  end

  defp do_start(function, api_url, api_key, opts) do
    {client_opts, endpoint_opts} = Keyword.split(opts, [:stream_to, :keep_alive])

    client_opts =
      client_opts
      |> Keyword.put_new(:stream_to, self())
      |> Keyword.put_new(:keep_alive, false)

    apply(GenServer, function, [__MODULE__, [api_url, api_key, client_opts, endpoint_opts]])
  end

  @doc """
  Sends a proper message over websocket to the API
  """
  @spec send_message(GenServer.server(), Start.t() | Stop.t()) :: :ok
  def send_message(client, %msg_module{} = msg) when msg_module in [Start, Stop] do
    GenServer.cast(client, {:send_message, msg})
  end

  @doc """
  Sends audio data over websocket
  """
  @spec send_data(GenServer.server(), iodata()) :: :ok
  def send_data(client, data) do
    GenServer.cast(client, {:send_data, data})
  end

  @doc """
  Stops the client process. A proxy for `GenServer.stop/3`.
  """
  @spec stop(GenServer.server(), reason :: term(), GenServer.timeout()) :: :ok
  def stop(client, reason \\ :normal, timeout \\ :infinity) do
    GenServer.stop(client, reason, timeout)
  end

  @impl true
  def init([api_url, api_key, client_opts, endpoint_opts]) do
    with {:ok, conn_pid} <- :gun.open(api_url, Util.ssl_port(), Util.ssl_connection_opts()) do
      monitor = Process.monitor(conn_pid)
      task = Task.async(Token, :get, [api_key])

      ws_path =
        case endpoint_opts do
          [] -> @endpoint_path
          _ -> @endpoint_path <> "?" <> URI.encode_query(endpoint_opts)
        end

      state = %{
        api_key: api_key,
        conn_pid: conn_pid,
        conn_monitor: monitor,
        stream_to: client_opts[:stream_to],
        keep_alive: client_opts[:keep_alive],
        token: nil,
        ws_path: ws_path,
        ws_ref: nil
      }

      {:ok, state, {:continue, {:init, task}}}
    end
  end

  @impl true
  def handle_continue({:init, task}, %{conn_pid: conn_pid, ws_path: ws_path} = state) do
    with {:ok, _protocol} <- :gun.await_up(conn_pid),
         {:ok, token} <- Task.await(task),
         ws_ref = :gun.ws_upgrade(conn_pid, ws_path, [token |> Token.auth_header()]),
         :ok <- await_upgrade(conn_pid, ws_ref) do
      {:noreply, %{state | token: token, ws_ref: ws_ref}}
    else
      {:error, reason} ->
        raise "Error while initializing connection: #{inspect(reason)}"
    end
  end

  @impl true
  def handle_cast({:send_message, msg}, %{conn_pid: conn_pid} = state) do
    encoded_msg = msg |> Jason.encode_to_iodata!()
    :gun.ws_send(conn_pid, {:text, encoded_msg})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_data, data}, %{conn_pid: conn_pid} = state) do
    :gun.ws_send(conn_pid, {:binary, data})
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:gun_ws, conn_pid, ws_ref, {:text, data}},
        %{conn_pid: conn_pid, ws_ref: ws_ref, stream_to: stream_to} = state
      ) do
    case Response.from_json(data) do
      {:ok, %Response{} = response} ->
        send(stream_to, response)
        {:noreply, state}

      {:ok, :listening} ->
        {:noreply, state}

      {:error, %Jason.DecodeError{} = error} ->
        raise "Error while decoding response: #{Jason.DecodeError.message(error)}"

      {:error, error} ->
        if error =~ "timed out" and state.keep_alive do
          {:noreply, reconnect(state)}
        else
          raise "Received error over websocket: #{error}"
        end
    end
  end

  @impl true
  def handle_info(
        {:DOWN, monitor, :process, conn_pid, reason},
        %{conn_pid: conn_pid, conn_monitor: monitor}
      ) do
    raise "Connection down: #{inspect(reason)}"
  end

  @impl true
  def handle_info(
        {:gun_response, :nofin, _code, _headers},
        %{conn_pid: conn_pid, ws_ref: ws_ref, monitor: monitor}
      ) do
    {:ok, body} = :gun.await_body(conn_pid, ws_ref, monitor)
    raise "Error while upgrading to websocket: #{inspect(Jason.decode!(body), pretty: true)}"
  end

  @impl true
  def handle_info({:gun_error, reason}, _state) do
    raise "Gun error: #{inspect(reason, pretty: true)}"
  end

  @impl true
  def handle_info(msg, _state) do
    raise "Unknown message: #{inspect(msg, pretty: true)}"
  end

  @impl true
  def terminate(_reason, state) do
    Process.demonitor(state.conn_monitor)
  end

  defp await_upgrade(conn_pid, ws_ref) do
    receive do
      {:gun_upgrade, ^conn_pid, ^ws_ref, ["websocket"], _} -> :ok
    after
      5000 -> raise "Timeout while waiting for connection upgrade"
    end
  end

  defp reconnect(%{conn_pid: conn_pid} = state) do
    token_res =
      if state.token |> Token.should_refresh?() do
        Token.get(state.api_key)
      else
        {:ok, state.token}
      end

    with {:ok, token} <- token_res,
         {:ok, _protocol} <- :gun.await_up(conn_pid),
         :ok = :gun.flush(conn_pid),
         ws_ref = :gun.ws_upgrade(conn_pid, state.ws_path, [token |> Token.auth_header()]),
         :ok <- await_upgrade(conn_pid, ws_ref) do
      %{state | token: token, ws_ref: ws_ref}
    else
      {:error, reason} -> raise "Error while reconnecting: #{inspect(reason)}"
    end
  end
end
