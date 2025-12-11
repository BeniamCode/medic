# priv/repo/reindex.exs
alias Medic.Doctors
alias Medic.Search

IO.puts "\n--- Typesense Connection Check ---"

IO.puts "1. Checking Database Doctors..."
doctors = Doctors.list_doctors()
count = length(doctors)
IO.puts "   Found #{count} doctors in DB."

if count > 0 do
  IO.puts "2. Syncing to Typesense..."
  case Search.sync_all_doctors() do
    {:ok, synced_count} -> IO.puts "   Successfully synced #{synced_count} documents."
    error -> IO.puts "   Sync Failed: #{inspect(error)}"
  end

  IO.puts "3. Test Search Query..." 
  case Search.search_doctors(query: "*") do
    {:ok, %{total: total}} -> IO.puts "   Typesense returned #{total} hits."
    error -> IO.puts "   Search Failed: #{inspect(error)}"
  end
else
  IO.puts "   Skipping sync (No doctors in DB). Please verify seeds."
end

IO.puts "--- End Check ---\n"
