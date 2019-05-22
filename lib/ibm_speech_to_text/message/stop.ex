defmodule IBMSpeechToText.Message.Stop do
  @moduledoc """
  Message (struct) marking the end of data to be recognized.
  """

  @type t() :: %__MODULE__{}

  defstruct []
end

defimpl Jason.Encoder, for: IBMSpeechToText.Message.Stop do
  def encode(_value, opts) do
    %{action: "stop"} |> Jason.Encode.map(opts)
  end
end
