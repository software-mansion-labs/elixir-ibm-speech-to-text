defmodule IBMSpeechToText.Message.StartEncodingTest do
  use ExUnit.Case, async: true
  alias IBMSpeechToText.Message.Start

  @content_type_map %{
    {:alaw, 8000} => "audio/alaw;rate=8000",
    {:basic, 8000} => "audio/basic;rate=8000",
    :flac => "audio/flac",
    :g729 => "audio/g729",
    {:l16, 8000} => "audio/l16;rate=8000",
    {:l16, 8000, 2} => "audio/l16;rate=8000;channels=2",
    :mp3 => "audio/mp3",
    :mpeg => "audio/mpeg",
    {:mulaw, 8000} => "audio/mulaw;rate=8000",
    :ogg => "audio/ogg",
    :wav => "audio/wav",
    :webm => "audio/webm",
    {:ogg, :opus} => "audio/ogg;codecs=opus",
    {:ogg, :vorbis} => "audio/ogg;codecs=vorbis",
    {:webm, :opus} => "audio/webm;codecs=opus",
    {:webm, :vorbis} => "audio/webm;codecs=vorbis"
  }

  test "Remove nil fields" do
    assert %Start{} |> Jason.encode!() == ~s/{"action":"start"}/
  end

  test "content_type encoding" do
    json = %Start{content_type: :flac} |> Jason.encode!()

    assert json |> String.contains?("content-type"), """
    JSON #{json} does not contain content-type field
    (note the dash instead of underscore)
    """

    @content_type_map
    |> Enum.each(fn {entry, content_type_string} ->
      json = %Start{content_type: entry} |> Jason.encode!()

      assert json |> String.contains?(content_type_string), """
      JSON #{json} does not contain content_type #{content_type_string}
      """
    end)
  end
end
