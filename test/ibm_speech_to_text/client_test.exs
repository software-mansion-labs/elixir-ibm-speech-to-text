defmodule IBMSpeechToText.ClientTest do
  use ExUnit.Case, async: true
  alias IBMSpeechToText.{Client, Response}
  alias IBMSpeechToText.Message.{Start, Stop}

  defp fixture(file) do
    Path.join([__DIR__, "../fixtures/", file])
  end

  describe "[External]" do
    @describetag :external

    test "Get transcript from the API" do
      assert {:ok, pid} =
               Client.start_link(:frankfurt, Application.get_env(:ibm_speech_to_text, :api_key))

      Client.send_message(pid, %Start{})
      Client.send_data(pid, File.read!(fixture("sample.flac")))
      Client.send_message(pid, %Stop{})

      assert_receive %Response{results: [result_a, result_b]}, 10000
      assert [alternative] = result_a.alternatives
      assert alternative.transcript == "to Sherlock Holmes she's always the woman "
      assert [alternative] = result_b.alternatives
      assert alternative.transcript == "I have seldom heard him mention her on to any other name "
    end
  end
end
