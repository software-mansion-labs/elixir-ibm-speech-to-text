defmodule IBMSpeechToText.Message.Stop do
  defstruct []
end

defimpl Jason.Encoder, for: IBMSpeechToText.Message.Stop do
  def encode(_value, opts) do
    %{action: "stop"} |> Jason.Encode.map(opts)
  end
end
