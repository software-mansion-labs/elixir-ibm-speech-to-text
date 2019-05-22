# IBM Cloud Speech to Text

Elixir client for [IBM Cloud Speech to Text service](https://cloud.ibm.com/docs/services/speech-to-text)

## Installation

The package can be installed by adding `:ibm_speech_to_text` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ibm_speech_to_text, "~> 0.1.0"}
  ]
end
```

The docs can be found on [hexdocs.pm](https://hexdocs.pm/ibm_speech_to_text)

## Usage

1. Start the client process. For that you need to pass API URL or region as an atom,
   API key obtained from IBM Cloud console. `start_link` also accepts parameters for the endpoint,
   see the docs for more details.

    ```elixir
    {:ok, pid} = IBMSpeechToText.Client.start_link(:frankfurt, "API_KEY", model: "en-GB_BroadbandModel")
    ```

2. Send "start" event with configuration for speech recognition

    ```elixir
    start_message = %IBMSpeechToText.Start{content_type: :flac}
    IBMSpeechToText.Client.send_message(pid, start_message)
    ```

3. Start audio streaming

    ```elixir
    IBMSpeechToText.Client.send_data(pid, audio_data)
    ```

4. Stop streaming by sending "stop" message

    ```elixir
    stop_message = %IBMSpeechToText.Stop{}
    IBMSpeechToText.Client.send_message(pid, stop_message)
    ```

5. You will receive results via message with struct `IBMSpeechToText.Response`

    ```elixir
    %IBMSpeechToText.Response{
      result_index: 0,
      results: [
        %IBMSpeechToText.RecognitionResult{
          alternatives: [
            %IBMSpeechToText.RecognitionAlternative{
              confidence: 0.87,
              timestamps: nil,
              transcript: "to Sherlock Holmes she's always the woman ",
              word_confidence: nil
            }
          ],
          final: true,
          keywords_result: nil,
          word_alternatives: nil
        }, ...
      ],
      speaker_labels: nil,
      warnings: nil
    }
    ```

## Testing

Test tagged `:external` is excluded by default since it contacts the real API and requires
an API key provided via config.
This can be done by adding `config/test.secret.exs` file with the following content:

```elixir
use Mix.Config

config :ibm_speech_to_text, api_key: "YOUR_API_KEY"
```

## Fixture

A recording fragment in `test/fixtures` comes from an audiobook
"The adventures of Sherlock Holmes (version 2)" available on [LibriVox](https://librivox.org/the-adventures-of-sherlock-holmes-by-sir-arthur-conan-doyle/)

## Status

There are a few things that are not implemented in current version:

- parsing "speaker_labels" in Response
- parsing "word_alternatives" and "keywords_result" in RecognitionResult
- better way to pass endpoint options to client

## Sponsors

This project is sponsored by [Abridge AI, Inc.](https://abridge.ai)

## Copyright and License

Copyright 2019, [Software Mansion](https://swmansion.com)

[![Software Mansion](https://membraneframework.github.io/static/logo/swm_logo_readme.png)](https://swmansion.com)

Licensed under the [Apache License, Version 2.0](LICENSE)