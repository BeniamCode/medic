# Run this script with: mix run priv/repo/seeds/import_hospitals.exs

Medic.Hospitals.Importer.import_from_csv("/Users/beniam/Documents/on_duty_dec.csv")
IO.puts "✅ Hospital data imported successfully."
