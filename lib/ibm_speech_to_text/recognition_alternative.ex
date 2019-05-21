defmodule IBMSpeechToText.RecognitionAlternative do
  @moduledoc """
  Recognition alternative obtained via `IBMSpeechToText.Result`.

  Elixir representation of `SpeechRecognitionAlternative` described
  [here](https://cloud.ibm.com/apidocs/speech-to-text#recognize-audio) in "Response" part
  """

  @struct_keys [:transcript, :confidence, :timestamps, :word_confidence]
  @enforce_keys [:transcript]
  defstruct @struct_keys

  @type t() :: %__MODULE__{
          transcript: String.t(),
          confidence: float(),
          timestamps: [{String.t(), float(), float()}] | nil,
          word_confidence: [{String.t(), float()}] | nil
        }

  @doc false
  @spec from_map(%{required(String.t()) => String.t()}) :: %__MODULE__{}
  def from_map(map) do
    parsed_keyword =
      Enum.map(@struct_keys, fn key_atom ->
        key_string = Atom.to_string(key_atom)
        parse_entry(key_atom, map[key_string])
      end)

    struct!(__MODULE__, parsed_keyword)
  end

  defp parse_entry(:timestamps, ts_lists) when is_list(ts_lists) do
    timestamps =
      ts_lists
      |> Enum.map(fn [word, start_ts, end_ts] ->
        {word, start_ts, end_ts}
      end)

    {:timestamps, timestamps}
  end

  defp parse_entry(:word_confidence, conf_lists) when is_list(conf_lists) do
    confidences =
      conf_lists
      |> Enum.map(fn [word, confidence] ->
        {word, confidence}
      end)

    {:timestamps, confidences}
  end

  defp parse_entry(key_atom, value) do
    {key_atom, value}
  end
end
