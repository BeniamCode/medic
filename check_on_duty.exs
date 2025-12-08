alias Medic.Hospitals

today = ~D[2025-12-07]
IO.puts "Listing on-duty hospitals for: #{today}"

hospitals = Hospitals.list_on_duty_hospitals(today)
IO.puts "Found #{length(hospitals)} hospitals."

Enum.each(hospitals, fn h ->
  IO.puts "- #{h.name} (#{h.city})"
  Enum.each(h.hospital_schedules, fn s ->
    IO.inspect(s.specialties, label: "  Specialties")
  end)
end)
