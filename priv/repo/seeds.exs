# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# This script dispatches to environment-specific seeds:
#   - prod.exs: Essential data (specialties)
#   - dev.exs: Development data (demo doctors, patients, appointments)

seeds_dir = Path.dirname(__ENV__.file) <> "/seeds"

# Always run production seeds (essential data)
Code.require_file("prod.exs", seeds_dir)

# Appreciation system seeds (achievements definitions)
Code.require_file("appreciate.exs", seeds_dir)

# Run development seeds only in dev/test
if Mix.env() in [:dev, :test] do
  Code.require_file("dev.exs", seeds_dir)
end
