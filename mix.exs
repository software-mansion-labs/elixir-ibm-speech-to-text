defmodule IbmSpeechToText.MixProject do
  use Mix.Project

  @version "0.1.0"
  @github_url "https://github.com/SoftwareMansion/elixir-ibm-speech-to-text"

  def project do
    [
      app: :ibm_speech_to_text,
      version: @version,
      elixir: "~> 1.8",
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
      extra_applications: [:logger]
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
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}"
    ]
  end
end
