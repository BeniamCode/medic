import Config

if database_url = System.get_env("DATABASE_URL") do
  config :medic, Medic.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "20"),
    ssl: [verify: :verify_none]
end

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.
# The block below contains prod specific runtime configuration.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/medic start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :medic, MedicWeb.Endpoint, server: true
end

config :medic, MedicWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT", "4000"))]

config :medic, Medic.Storage.B2,
  key_id: System.get_env("B2_KEY_ID"),
  application_key: System.get_env("B2_APPLICATION_KEY"),
  bucket_id: System.get_env("B2_BUCKET_ID"),
  bucket_name: System.get_env("B2_BUCKET_NAME")

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: postgresql://user:pass@host/database
      """

  config :medic, Medic.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "20"),
    ssl: [verify: :verify_none]

  # The secret key base is used to sign/encrypt cookies and other secrets.
  # A default value is used in config/dev.exs and config/test.exs but you
  # want to use a different value for prod and you most likely don't want
  # to check this value into version control, so we use an environment
  # variable instead.
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"

  config :medic, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :medic, MedicWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      # Enable IPv6 and bind on all interfaces.
      # Set it to  {0, 0, 0, 0, 0, 0, 0, 1} for local network only access.
      # See the documentation on https://hexdocs.pm/bandit/Bandit.html#t:options/0
      # for details about using IPv6 vs IPv4 and loopback vs public addresses.
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base

  # ## SSL Support
  #
  # To get SSL working, you will need to add the `https` key
  # to your endpoint configuration:
  #
  #     config :medic, MedicWeb.Endpoint,
  #       https: [
  #         ...,
  #         port: 443,
  #         cipher_suite: :strong,
  #         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
  #         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
  #       ]
  #
  # The `cipher_suite` is set to `:strong` to support only the
  # latest and more secure SSL ciphers. This means old browsers
  # and clients may not be supported. You can set it to
  # `:compatible` for wider support.
  #
  # `:keyfile` and `:certfile` expect an absolute path to the key
  # and cert in disk or a relative path inside priv, for example
  # "priv/ssl/server.key". For all supported SSL configuration
  # options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
  #
  # We also recommend setting `force_ssl` in your config/prod.exs,
  # ensuring no data is ever sent via http, always redirecting to https:
  #
  #     config :medic, MedicWeb.Endpoint,
  #       force_ssl: [hsts: true]
  #
  # Check `Plug.SSL` for all available options in `force_ssl`.

  # ## Configuring the mailer
  #
  # Gmail SMTP configuration for Google Workspace (Gmail for Business)
  # Uses the GMAIL_SMTP_APP app password (single app password for all aliases)
  # The username can be any of your aliases - hi@, appointments@, etc.
  config :logger, level: :debug
  
  config :medic, Medic.Mailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: "smtp.gmail.com",
    port: 587,
    username: System.get_env("HI_USERNAME") || "hi@medic.gr",
    password: System.get_env("GMAIL_SMTP_APP"),
    ssl: false,
    tls: :always,
    tls_options: [
      verify: :verify_peer,
      cacertfile: CAStore.file_path(),
      depth: 3
    ],
    auth: :always,
    retries: 2,
    no_mx_lookups: false

  config :medic, Medic.AppointmentsMailer,
    adapter: Swoosh.Adapters.SMTP,
    relay: "smtp.gmail.com",
    port: 587,
    username: "appointments@medic.gr",
    password: System.get_env("APPOINTMENTS_SMTP_APP"),
    ssl: false,
    tls: :always,
    tls_options: [
      verify: :verify_peer,
      cacertfile: CAStore.file_path(),
      depth: 3
    ],
    auth: :always,
    retries: 2,
    no_mx_lookups: false

  config :ex_typesense,
    api_key: System.get_env("TYPESENSE_API_KEY") || "xyz",
    host: System.get_env("TYPESENSE_HOST") || "localhost",
    port: String.to_integer(System.get_env("TYPESENSE_PORT") || "8108"),
    scheme: System.get_env("TYPESENSE_SCHEME") || "http"

end
