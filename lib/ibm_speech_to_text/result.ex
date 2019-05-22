defmodule IBMSpeechToText.RecognitionResult do
  @moduledoc """
  Recognition result obtained via `IBMSpeechToText.Response`.

  Elixir representation of `SpeechRecognitionResult` described
  [here](https://cloud.ibm.com/apidocs/speech-to-text#recognize-audio) in "Response" part
  """

  alias IBMSpeechToText.RecognitionAlternative

  @struct_keys [:final, :alternatives, :keywords_result, :word_alternatives]
  @enforce_keys [:final, :alternatives]
  defstruct @struct_keys

  @type t() :: %__MODULE__{
          final: boolean(),
          alternatives: [RecognitionAlternative.t()],
          keywords_result: %{required(String.t()) => map()},
          word_alternatives: [map()]
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

  defp parse_entry(:alternatives, alt_list) when is_list(alt_list) do
    {:alternatives, Enum.map(alt_list, &RecognitionAlternative.from_map/1)}
  end

  # TODO: word_alternatives and keywords_result parsing

  defp parse_entry(key_atom, value) do
    {key_atom, value}
  end
end
