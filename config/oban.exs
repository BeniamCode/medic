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
        {"0 3 * * *", Medic.Workers.AppreciationMaintenance},
        {"*/15 * * * *", Medic.Workers.AppointmentReminder}
      ]
    }
  ],
  queues: [default: 5, mailers: 5, search: 5, maintenance: 2]
