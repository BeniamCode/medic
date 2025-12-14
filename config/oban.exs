import Config

# Shared Oban configuration.
# Loaded by dev/prod and overridden by env-specific settings if needed.

config :medic, Oban,
  repo: Medic.Repo,
  plugins: [
    Oban.Plugins.Pruner,
    {
      Oban.Plugins.Cron,
      crontab: [
        {"*/1 * * * *", Medic.Workers.AppointmentAutoComplete},
        {"0 3 * * *", Medic.Workers.AppreciationMaintenance}
      ]
    }
  ],
  queues: [default: 10, mailers: 10, search: 10, maintenance: 2]
