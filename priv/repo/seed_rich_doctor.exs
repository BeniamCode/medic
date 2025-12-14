# priv/repo/seed_rich_doctor.exs

alias Medic.Doctors

# Fetch the first doctor
doctor = Doctors.list_doctors() |> List.first()

if doctor do
  IO.puts("Updating doctor: #{doctor.first_name} #{doctor.last_name}")

  Doctors.update_doctor(doctor, %{
    title: "Prof. Dr.",
    registration_number: "GMC-12345678",
    years_of_experience: 15,
    hospital_affiliation: "St. Luke's Leading Heart Center",
    academic_title: "Professor of Cardiology",
    telemedicine_available: true,
    bio: """
    I am a senior cardiologist with over 15 years of experience in treating complex heart conditions.
    My philosophy is patient-first, ensuring that every individual understands their heart health and treatment options.
    I specialize in minimally invasive procedures and preventative cardiology.
    """,
    sub_specialties: ["Interventional Cardiology", "Preventative Cardiology", "Heart Failure Management"],
    clinical_procedures: ["Angioplasty", "Stent Placement", "TAVR", "Stress Testing", "Echocardiography"],
    conditions_treated: ["Coronary Artery Disease", "Arrhythmia", "Hypertension", "High Cholesterol"],
    languages: ["English", "Greek", "German"],
    insurance_networks: ["Bupa", "Allianz", "Generali", "MetLife"],
    accessibility_items: ["Wheelchair Accessible", "Elevator", "Parking Available"],
    board_certifications: ["European Board of Cardiology", "Greek Board of Cardiology"],
    awards: ["Top Doctor 2024", "Excellence in Research 2022"],
    publications: [
      "Advances in TAVR Outcomes - JACC 2023",
      "Preventative Measures in Hypertension - Lancet 2021"
    ]
  })
  |> case do
    {:ok, updated_doctor} ->
      IO.puts("Successfully updated doctor profile!")
      IO.inspect(updated_doctor, label: "Updated Fields")
    {:error, error} ->
      IO.inspect(error, label: "Failed to update doctor")
  end
else
  IO.puts("No doctors found to update.")
end
