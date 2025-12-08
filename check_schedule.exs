alias Medic.Repo
alias Medic.Hospitals.HospitalSchedule
import Ecto.Query

today = ~D[2025-12-07]
IO.puts "Checking schedules for: #{today}"

schedules = Repo.all(from s in HospitalSchedule, where: s.date == ^today)
IO.puts "Found #{length(schedules)} schedules."

Enum.each(schedules, fn s ->
  IO.inspect(s, label: "Schedule")
end)
