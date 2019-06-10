defmodule IBMSpeechToText.Response do
  @moduledoc """
  Elixir representation of response body from the Speech to Text API.
  Described [here](https://cloud.ibm.com/apidocs/speech-to-text#recognize-audio) in "Response" part
  """

  alias IBMSpeechToText.RecognitionResult

  @type t() :: %__MODULE__{
          results: [RecognitionResult.t()],
          result_index: non_neg_integer(),
          speaker_labels: map(),
          warnings: [String.t()]
        }

  @struct_keys [:results, :result_index, :speaker_labels, :warnings]
  defstruct @struct_keys

  @doc """
  Parse JSON response from the API into struct `#{inspect(__MODULE__)}`
  """
  @spec from_json(String.t()) ::
          {:ok, __MODULE__.t()}
          | {:ok, :listening}
          | {:error, String.t()}
          | {:error, Jason.DecodeError.t()}
  def from_json(input) do
    with {:ok, map} <- Jason.decode(input) do
      from_map(map)
    end
  end

  @doc false
  @spec from_map(%{required(String.t()) => String.t()}) ::
          {:ok, %__MODULE__{}} | {:ok, :listening} | {:error, String.t()}
  def from_map(%{"state" => "listening"}) do
    {:ok, :listening}
  end

  def from_map(%{"error" => error}) do
    {:error, error}
  end

  def from_map(map) when is_map(map) do
    parsed_keyword =
      Enum.map(@struct_keys, fn key_atom ->
        key_string = Atom.to_string(key_atom)
        parse_entry(key_atom, map[key_string])
      end)

    {:ok, struct!(__MODULE__, parsed_keyword)}
  end

  defp parse_entry(:results, value) when value != nil do
    {:results, Enum.map(value, &RecognitionResult.from_map(&1))}
  end

  # TODO: speaker_labels parsing

  defp parse_entry(key_atom, value) do
    {key_atom, value}
  end
end

defimpl Jason.Encoder, for: IBMSpeechToText.Response do
  def encode(value, opts) do
    value
    |> Map.from_struct()
    |> Enum.filter(fn {_key, val} -> val != nil end)
    |> Map.new()
    |> Jason.Encode.map(opts)
  end
end
