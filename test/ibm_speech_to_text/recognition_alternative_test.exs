defmodule IBMSpeechToText.RecognitionAlternativeTest do
  use ExUnit.Case, async: true
  alias IBMSpeechToText.RecognitionAlternative

  test "parse basic recognition alternative" do
    example_alternative = %{"confidence" => 0.77, "transcript" => "some text"}

    assert RecognitionAlternative.from_map(example_alternative) == %RecognitionAlternative{
             confidence: 0.77,
             transcript: "some text"
           }
  end

  test "parse recognition alternative with timestamps" do
    example_alternative = %{
      "confidence" => 0.77,
      "transcript" => "some text",
      "timestamps" => [["some", 0.0, 1.2], ["text", 1.2, 2.5]]
    }

    assert RecognitionAlternative.from_map(example_alternative) == %RecognitionAlternative{
             confidence: 0.77,
             transcript: "some text",
             timestamps: [
               {"some", 0.0, 1.2},
               {"text", 1.2, 2.5}
             ]
           }
  end

  test "parse recognition alternative with word confidence" do
    example_alternative = %{
      "confidence" => 0.77,
      "transcript" => "some text",
      "word_confidence" => [["some", 0.95], ["text", 0.866]]
    }

    assert RecognitionAlternative.from_map(example_alternative) == %RecognitionAlternative{
             confidence: 0.77,
             transcript: "some text",
             timestamps: [
               {"some", 0.95},
               {"text", 0.866}
             ]
           }
  end
end
