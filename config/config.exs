# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :logger, :console,
  format: "\n$date $time [$level] $levelpad$message"

config :extwitter, :oauth, [
  consumer_key: System.get_env("TWITTER_CONSUMER_KEY"),
  consumer_secret: System.get_env("TWITTER_CONSUMER_SECRET"),
  access_token: System.get_env("TWITTER_ACCESS_TOKEN"),
  access_token_secret: System.get_env("TWITTER_ACCESS_TOKEN_SECRET")
]

if File.exists?("config/config.secret.exs") do
  import_config "config.secret.exs"
end
