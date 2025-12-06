import Config

# Typesense configuration
# Use environment variables in production
config :ex_typesense,
  api_key: System.get_env("TYPESENSE_API_KEY") || "xyz",
  host: System.get_env("TYPESENSE_HOST") || "localhost",
  port: String.to_integer(System.get_env("TYPESENSE_PORT") || "8108"),
  scheme: System.get_env("TYPESENSE_SCHEME") || "http"
