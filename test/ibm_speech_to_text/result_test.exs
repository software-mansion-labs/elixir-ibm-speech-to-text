defmodule IBMSpeechToText.ResultTest do
  use ExUnit.Case, async: true
  alias IBMSpeechToText.{Result, RecognitionAlternative}

  test "parse response" do
    alternatives = [
      %{
        "confidence" => 0.77,
        "transcript" => "the marketing potential there is huge "
      }
    ]

    keywords_result = %{
      "colorado" => [
        %{
          "normalized_text" => "marketing",
          "start_time" => 0.58,
          "confidence" => 0.96,
          "end_time" => 1.16
        }
      ]
    }

    example_result = %{
      "alternatives" => alternatives,
      "final" => true,
      "keywords_result" => keywords_result
    }

    parsed_alternatives = alternatives |> Enum.map(&RecognitionAlternative.from_map/1)

    assert Result.from_map(example_result) == %Result{
             final: true,
             alternatives: parsed_alternatives,
             keywords_result: keywords_result
           }
  end
end
