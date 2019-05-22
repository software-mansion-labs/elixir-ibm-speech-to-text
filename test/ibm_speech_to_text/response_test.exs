defmodule IBMSpeechToText.ResponseTest do
  use ExUnit.Case, async: true
  alias IBMSpeechToText.{Response, RecognitionResult}

  test "parse response" do
    results = [
      %{
        "alternatives" => [
          %{
            "confidence" => 0.77,
            "transcript" => "the marketing potential there is huge "
          }
        ],
        "final" => true
      }
    ]

    speaker_labels = [
      %{
        "from" => 0.0,
        "to" => 1.2,
        "speaker" => 0,
        "confidence" => 0.95,
        "final" => true
      }
    ]

    example_response = %{
      "result_index" => 0,
      "results" => results,
      "speaker_labels" => speaker_labels,
      "warnings" => ["some warning"]
    }

    parsed_results = Enum.map(results, &RecognitionResult.from_map(&1))

    assert Response.from_map(example_response) ==
             {:ok,
              %Response{
                results: parsed_results,
                result_index: 0,
                speaker_labels: speaker_labels,
                warnings: ["some warning"]
              }}
  end
end
