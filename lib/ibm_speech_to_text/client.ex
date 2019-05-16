defmodule IBMSpeechToText.Client do
  use GenServer
  alias IBMSpeechToText.{Token, Util}

  @endpoint_path "/speech-to-text/api/v1/recognize"

  @spec start_link(IBMSpeechToText.region() | charlist(), String.t(), pid()) ::
          :ignore | {:error, any()} | {:ok, pid()}
  def start_link(api_region_or_url, api_key, stream_to \\ self())

  def start_link(region, api_key, stream_to) when is_atom(region) do
    with {:ok, api_url} <- IBMSpeechToText.api_host_name(region) do
      start_link(api_url, api_key, stream_to)
    end
  end

  def start_link(api_url, api_key, stream_to) do
    GenServer.start_link(__MODULE__, [api_url, api_key, stream_to])
  end

  @impl true
  def init([api_url, api_key, stream_to]) do
    with {:ok, conn_pid} <- :gun.open(api_url, Util.ssl_port(), Util.ssl_connection_opts()) do
      monitor = Process.monitor(conn_pid)
      task = Task.async(Token, :get, [api_key])

      state = %{
        conn_pid: conn_pid,
        conn_monitor: monitor,
        stream_to: stream_to,
        ws_ref: nil
      }

      {:ok, state, {:continue, {:init, task}}}
    end
  end

  @impl true
  def handle_continue({:init, task}, %{conn_pid: conn_pid} = state) do
    with {:ok, _protocol} <- :gun.await_up(conn_pid),
         {:ok, token} <- Task.await(task),
         ws_ref = :gun.ws_upgrade(conn_pid, @endpoint_path, [token |> Token.auth_header()]),
         :ok <- await_upgrade(conn_pid, ws_ref) do
      {:noreply, %{state | ws_ref: ws_ref}}
    else
      {:error, reason} ->
        raise "Error while initializing connection: #{inspect(reason)}"
    end
  end

  @impl true
  def handle_cast(:start, %{conn_pid: conn_pid} = state) do
    start = %{action: "start"} |> Jason.encode_to_iodata!()
    :gun.ws_send(conn_pid, {:text, start})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:send_data, data}, %{conn_pid: conn_pid} = state) do
    :gun.ws_send(conn_pid, {:binary, data})
    {:noreply, state}
  end

  @impl true
  def handle_cast(:stop, %{conn_pid: conn_pid} = state) do
    stop = %{action: "stop"} |> Jason.encode_to_iodata!()
    :gun.ws_send(conn_pid, {:text, stop})
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:gun_ws, conn_pid, ws_ref, {:text, data}},
        %{conn_pid: conn_pid, ws_ref: ws_ref, stream_to: stream_to} = state
      ) do
    case Jason.decode!(data) do
      %{"results" => _} = res ->
        send(stream_to, res)
        {:noreply, state}

      %{"state" => "listening"} ->
        {:noreply, state}

      %{"error" => error} ->
        raise "Received error over websocket: #{inspect(error)}"
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
end
