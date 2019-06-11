defmodule IbmSpeechToText.MixProject do
  use Mix.Project

  @version "0.1.2"
  @github_url "https://github.com/SoftwareMansion/elixir-ibm-speech-to-text"

  def project do
    [
      app: :ibm_speech_to_text,
      version: @version,
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # hex
      description: "Elixir client for IBM Cloud Speech to Text service",
      package: package(),

      # docs
      name: "IBM Speech to Text",
      source_url: @github_url,
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:gun, "~> 1.3"},
      {:jason, "~> 1.1"},
      {:certifi, "~> 2.5"}
    ]
  end

  defp package do
    [
      maintainers: ["Bartosz Błaszków"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url
      }
    ]
  end

  defp docs do
    alias IBMSpeechToText.{
      Response,
      RecognitionResult,
      RecognitionAlternative,
      SpeakerLabelsResult
    }

    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [IBMSpeechToText, IBMSpeechToText.Message],
      groups_for_modules: [
        Messages: ~r/IBMSpeechToText.Message/,
        "API Responses": [
          Response,
          RecognitionResult,
          RecognitionAlternative,
          SpeakerLabelsResult
        ]
      ]
    ]
  end
end
