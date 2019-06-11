defmodule IBMSpeechToText.ResponseTest do
  use ExUnit.Case, async: true
  alias IBMSpeechToText.{Response, RecognitionResult, SpeakerLabelsResult}

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
    parsed_labels = Enum.map(speaker_labels, &SpeakerLabelsResult.from_map(&1))

    assert Response.from_map(example_response) ==
             {:ok,
              %Response{
                results: parsed_results,
                result_index: 0,
                speaker_labels: parsed_labels,
                warnings: ["some warning"]
              }}
  end

  test "parse and then re-encode response with recognition results" do
    json =
      "{\"result_index\":0,\"results\":[{\"alternatives\":[{\"confidence\":1,\"transcript\":\"a line of severe thunderstorms with several possible tornadoes is approaching Colorado on Sunday \"}],\"final\":true,\"keywords_result\":{\"colorado\":[{\"confidence\":0.96,\"end_time\":5.16,\"normalized_text\":\"Colorado\",\"start_time\":4.58}],\"tornadoes\":[{\"confidence\":1,\"end_time\":3.85,\"normalized_text\":\"tornadoes\",\"start_time\":3.03}]},\"word_alternatives\":[{\"alternatives\":[{\"confidence\":1,\"word\":\"a\"}],\"end_time\":0.3,\"start_time\":0.15},{\"alternatives\":[{\"confidence\":1,\"word\":\"line\"}],\"end_time\":0.64,\"start_time\":0.3},{\"alternatives\":[{\"confidence\":1,\"word\":\"of\"}],\"end_time\":0.73,\"start_time\":0.64},{\"alternatives\":[{\"confidence\":1,\"word\":\"severe\"}],\"end_time\":1.08,\"start_time\":0.73},{\"alternatives\":[{\"confidence\":1,\"word\":\"thunderstorms\"}],\"end_time\":1.85,\"start_time\":1.08},{\"alternatives\":[{\"confidence\":1,\"word\":\"with\"}],\"end_time\":2,\"start_time\":1.85},{\"alternatives\":[{\"confidence\":1,\"word\":\"several\"}],\"end_time\":2.52,\"start_time\":2},{\"alternatives\":[{\"confidence\":1,\"word\":\"possible\"}],\"end_time\":3.03,\"start_time\":2.52},{\"alternatives\":[{\"confidence\":1,\"word\":\"tornadoes\"}],\"end_time\":3.85,\"start_time\":3.03},{\"alternatives\":[{\"confidence\":1,\"word\":\"is\"}],\"end_time\":4.13,\"start_time\":3.95},{\"alternatives\":[{\"confidence\":1,\"word\":\"approaching\"}],\"end_time\":4.58,\"start_time\":4.13},{\"alternatives\":[{\"confidence\":0.96,\"word\":\"Colorado\"}],\"end_time\":5.16,\"start_time\":4.58},{\"alternatives\":[{\"confidence\":0.95,\"word\":\"on\"}],\"end_time\":5.32,\"start_time\":5.16},{\"alternatives\":[{\"confidence\":0.98,\"word\":\"Sunday\"}],\"end_time\":6.04,\"start_time\":5.32}]}]}"

    assert {:ok, response} = Response.from_json(json)
    assert response |> Jason.encode!() == json
  end

  test "parse and then re-encode response with speaker labels" do
    json =
      "{\"speaker_labels\":[{\"confidence\":0.48,\"final\":false,\"from\":0.46,\"speaker\":0,\"to\":1.09},{\"confidence\":0.48,\"final\":false,\"from\":1.09,\"speaker\":0,\"to\":1.6},{\"confidence\":0.49,\"final\":false,\"from\":1.63,\"speaker\":1,\"to\":1.76},{\"confidence\":0.49,\"final\":false,\"from\":1.76,\"speaker\":1,\"to\":2.36},{\"confidence\":0.49,\"final\":false,\"from\":2.36,\"speaker\":1,\"to\":2.56},{\"confidence\":0.49,\"final\":false,\"from\":2.56,\"speaker\":1,\"to\":3.33},{\"confidence\":0.52,\"final\":false,\"from\":3.49,\"speaker\":2,\"to\":3.68},{\"confidence\":0.52,\"final\":false,\"from\":3.68,\"speaker\":2,\"to\":3.8},{\"confidence\":0.52,\"final\":false,\"from\":3.8,\"speaker\":2,\"to\":4.44},{\"confidence\":0.52,\"final\":false,\"from\":4.44,\"speaker\":2,\"to\":4.54},{\"confidence\":0.52,\"final\":false,\"from\":4.54,\"speaker\":2,\"to\":5.04},{\"confidence\":0.52,\"final\":false,\"from\":5.04,\"speaker\":2,\"to\":5.55},{\"confidence\":0.52,\"final\":false,\"from\":5.55,\"speaker\":2,\"to\":5.79},{\"confidence\":0.52,\"final\":false,\"from\":5.79,\"speaker\":2,\"to\":5.99},{\"confidence\":0.52,\"final\":false,\"from\":5.99,\"speaker\":2,\"to\":6.37},{\"confidence\":0.52,\"final\":false,\"from\":6.37,\"speaker\":2,\"to\":6.79},{\"confidence\":0.52,\"final\":false,\"from\":6.79,\"speaker\":2,\"to\":7.26}]}"

    assert {:ok, response} = Response.from_json(json)
    assert response |> Jason.encode!() == json
  end
end
