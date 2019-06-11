defmodule IBMSpeechToText.SpeakerLabelsResult do
  @moduledoc """
  Speaker labels obtained via `IBMSpeechToText.Response`.

  Elixir representation of `SpeakerLabelsResult` described
  [here](https://cloud.ibm.com/apidocs/speech-to-text#recognize-audio) in "Response" part
  """

  @derive Jason.Encoder
  @struct_keys [:from, :to, :speaker, :confidence, :final]
  @enforce_keys @struct_keys
  defstruct @struct_keys

  @type t() :: %__MODULE__{
          from: float(),
          to: float(),
          speaker: integer(),
          confidence: float(),
          final: boolean()
        }

  @doc false
  @spec from_map(%{required(String.t()) => String.t()}) :: %__MODULE__{}
  def from_map(map) do
    parsed_keyword =
      Enum.map(@struct_keys, fn key_atom ->
        key_string = Atom.to_string(key_atom)
        {key_atom, map[key_string]}
      end)

    struct!(__MODULE__, parsed_keyword)
  end
end
