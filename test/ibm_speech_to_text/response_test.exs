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

  test "parse and then re-encode" do
    json =
      "{\"result_index\":0,\"results\":[{\"alternatives\":[{\"confidence\":1,\"transcript\":\"a line of severe thunderstorms with several possible tornadoes is approaching Colorado on Sunday \"}],\"final\":true,\"keywords_result\":{\"colorado\":[{\"confidence\":0.96,\"end_time\":5.16,\"normalized_text\":\"Colorado\",\"start_time\":4.58}],\"tornadoes\":[{\"confidence\":1,\"end_time\":3.85,\"normalized_text\":\"tornadoes\",\"start_time\":3.03}]},\"word_alternatives\":[{\"alternatives\":[{\"confidence\":1,\"word\":\"a\"}],\"end_time\":0.3,\"start_time\":0.15},{\"alternatives\":[{\"confidence\":1,\"word\":\"line\"}],\"end_time\":0.64,\"start_time\":0.3},{\"alternatives\":[{\"confidence\":1,\"word\":\"of\"}],\"end_time\":0.73,\"start_time\":0.64},{\"alternatives\":[{\"confidence\":1,\"word\":\"severe\"}],\"end_time\":1.08,\"start_time\":0.73},{\"alternatives\":[{\"confidence\":1,\"word\":\"thunderstorms\"}],\"end_time\":1.85,\"start_time\":1.08},{\"alternatives\":[{\"confidence\":1,\"word\":\"with\"}],\"end_time\":2,\"start_time\":1.85},{\"alternatives\":[{\"confidence\":1,\"word\":\"several\"}],\"end_time\":2.52,\"start_time\":2},{\"alternatives\":[{\"confidence\":1,\"word\":\"possible\"}],\"end_time\":3.03,\"start_time\":2.52},{\"alternatives\":[{\"confidence\":1,\"word\":\"tornadoes\"}],\"end_time\":3.85,\"start_time\":3.03},{\"alternatives\":[{\"confidence\":1,\"word\":\"is\"}],\"end_time\":4.13,\"start_time\":3.95},{\"alternatives\":[{\"confidence\":1,\"word\":\"approaching\"}],\"end_time\":4.58,\"start_time\":4.13},{\"alternatives\":[{\"confidence\":0.96,\"word\":\"Colorado\"}],\"end_time\":5.16,\"start_time\":4.58},{\"alternatives\":[{\"confidence\":0.95,\"word\":\"on\"}],\"end_time\":5.32,\"start_time\":5.16},{\"alternatives\":[{\"confidence\":0.98,\"word\":\"Sunday\"}],\"end_time\":6.04,\"start_time\":5.32}]}]}"

    assert {:ok, response} = Response.from_json(json)
    assert response |> Jason.encode!() == json
  end
end
