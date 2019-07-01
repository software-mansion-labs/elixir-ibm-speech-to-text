use Mix.Config

secret_config = "#{Mix.env()}.secret.exs" |> Path.expand(__DIR__)

if File.exists?(secret_config) do
  import_config secret_config
end
