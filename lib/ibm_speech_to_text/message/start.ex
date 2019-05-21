defmodule IBMSpeechToText.Message.Start do
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

  @type content_type ::
          :alaw
          | :basic
          | :flac
          | :g729
          | :l16
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
