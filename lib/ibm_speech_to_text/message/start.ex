defmodule IBMSpeechToText.Message.Start do
  @moduledoc """
  Message sent over WebSocket before audio to be recognized

  Allows to configure recognition process. The options are documented
  in [IBM API docs](https://cloud.ibm.com/apidocs/speech-to-text#wstextmessages)

  If an option is set to `nil` it won't be included in a message and thus
  the default value for recognition will be used.
  """
  @type t() :: %__MODULE__{
          content_type: content_type() | nil,
          inactivity_timeout: integer() | nil,
          interim_results: boolean() | nil,
          keywords: [String.t()] | nil,
          keywords_threshold: float() | nil,
          max_alternatives: non_neg_integer() | nil,
          word_alternatives_threshold: float() | nil,
          word_confidence: boolean() | nil,
          timestamps: boolean() | nil,
          profanity_filter: boolean() | nil,
          smart_formatting: boolean() | nil,
          speaker_labels: boolean() | nil,
          redaction: boolean() | nil
        }

  @type sample_rate :: pos_integer()

  @type channels :: pos_integer()

  @type content_type ::
          {:alaw, sample_rate()}
          | {:basic, sample_rate()}
          | :flac
          | :g729
          | {:l16, sample_rate()}
          | {:l16, sample_rate(), channels()}
          | :mp3
          | :mpeg
          | :mulaw
          | :ogg
          | {:ogg, :opus}
          | {:ogg, :vorbis}
          | :wav
          | :webm
          | {:webm, :ogg}
          | {:webm, :vorbis}

  defstruct [
    :content_type,
    :customization_weight,
    :inactivity_timeout,
    :interim_results,
    :keywords,
    :keywords_threshold,
    :max_alternatives,
    :word_alternatives_threshold,
    :word_confidence,
    :timestamps,
    :profanity_filter,
    :smart_formatting,
    :speaker_labels,
    :grammar_name,
    :redaction
  ]
end

defimpl Jason.Encoder, for: IBMSpeechToText.Message.Start do
  def encode(value, opts) do
    value
    |> Map.from_struct()
    |> Enum.flat_map(fn
      {_key, nil} ->
        []

      {:content_type, {format, sample_rate}} when format in [:alaw, :mulaw, :basic, :l16] ->
        [{"content-type", "audio/#{format};rate=#{sample_rate}"}]

      {:content_type, {:l16, sample_rate, channels}} ->
        [{"content-type", "audio/l16;rate=#{sample_rate};channels=#{channels}"}]

      {:content_type, {format, codec}} ->
        [{"content-type", "audio/#{format};codecs=#{codec}"}]

      {:content_type, value} ->
        [{"content-type", "audio/#{value}"}]

      entry ->
        [entry]
    end)
    |> Map.new()
    |> Map.put(:action, "start")
    |> Jason.Encode.map(opts)
  end
end
