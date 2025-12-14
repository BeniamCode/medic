
alias Medic.Accounts
alias Medic.Patients
alias Medic.Doctors
alias Medic.Repo

# Helper to create patient
create_patient = fn email ->
  {:ok, user} = Accounts.register_user(%{
    email: email,
    password: "Password1234!",
    role: :patient
  })
  
  {:ok, patient} = Patients.create_patient(user, %{
    first_name: "Test",
    last_name: "Patient",
    date_of_birth: ~D[1990-01-01],
    phone_number: "+306900000000"
  })
  
  {user, patient}
end

# Helper to create doctor
create_doctor = fn email ->
  {:ok, user} = Accounts.register_user(%{
    email: email,
    password: "Password1234!",
    role: :doctor
  })
  
  # Get a specialty
  specialty = Repo.all(Medic.Doctors.Specialty) |> List.first()
  
  {:ok, doctor} = Doctors.create_doctor(user, %{
    first_name: "Test",
    last_name: "Doctor",
    specialty_id: specialty.id,
    consultation_fee: 50,
    city: "Athens",
    address: "123 Main St",
    phone_number: "+306900000001"
  })
  
  {user, doctor}
end

# 1. Get or create patient
patient_email = "patient@example.com"
{patient_user, patient} =
  case Accounts.get_user_by_email(patient_email) do
    %Medic.Accounts.User{} = user -> 
      patient = Patients.get_patient_by_user_id(user.id)
      # If patient profile missing, create it
      if is_nil(patient) do
         {:ok, patient} = Patients.create_patient(user, %{
            first_name: "Test",
            last_name: "Patient",
            date_of_birth: ~D[1990-01-01],
            phone_number: "+306900000000"
          })
          {user, patient}
      else
          {user, patient}
      end
    nil -> 
      IO.puts("Creating patient #{patient_email}...")
      create_patient.(patient_email)
  end

# 2. Get or create doctor
doctor_email = "doctor@example.com"
{_doctor_user, doctor} =
  case Accounts.get_user_by_email(doctor_email) do
    %Medic.Accounts.User{} = user -> 
      doctor = Doctors.get_doctor_by_user_id(user.id)
      # If doctor profile missing, create it
      if is_nil(doctor) do
          specialty = Repo.all(Medic.Doctors.Specialty) |> List.first()
          {:ok, doctor} = Doctors.create_doctor(user, %{
            first_name: "Test",
            last_name: "Doctor",
            specialty_id: specialty.id,
            consultation_fee: 50,
            city: "Athens",
            address: "123 Main St",
            phone_number: "+306900000001"
          })
          {user, doctor}
      else
          {user, doctor}
      end
    nil -> 
      IO.puts("Creating doctor #{doctor_email}...")
      create_doctor.(doctor_email)
  end

# 3. Create a completed appointment in the past
IO.puts("Creating appointment for #{patient.first_name} with Dr. #{doctor.last_name}...")

base_starts_at =
  DateTime.utc_now()
  |> DateTime.add(-10, :day)
  |> DateTime.truncate(:second)

appointment =
  Enum.reduce_while(0..48, nil, fn hour_offset, _acc ->
    starts_at = DateTime.add(base_starts_at, hour_offset, :hour)
    ends_at = DateTime.add(starts_at, 30, :minute)

    create_result =
      Medic.Appointments.Appointment
      |> Ash.Changeset.for_create(:create, %{
        starts_at: starts_at,
        ends_at: ends_at,
        doctor_id: doctor.id,
        patient_id: patient.id,
        status: "held",
        consultation_mode_snapshot: "in_person",
        price_cents: 5000,
        currency: "EUR"
      })
      |> Ash.create()

    case create_result do
      {:ok, held} ->
        with {:ok, confirmed} <-
               held
               |> Ash.Changeset.for_update(:update, %{status: "confirmed"})
               |> Ash.update(),
             {:ok, completed} <-
               confirmed
               |> Ash.Changeset.for_update(:update, %{status: "completed"})
               |> Ash.update() do
          {:halt, completed}
        else
          {:error, err} ->
            raise "Unable to update appointment status: #{inspect(err)}"
        end

      {:error, error} ->
        error_text = inspect(error)

        if String.contains?(error_text, "no_double_bookings") do
          {:cont, nil}
        else
          raise "Unable to create appointment: #{error_text}"
        end
    end
  end)

if is_nil(appointment) do
  raise "Unable to find a free time slot to seed an appointment"
end

IO.puts("""
=======================================================
Test Appointment Created!
=======================================================
Patient Email: #{patient_user.email}
Password: Password1234!
Doctor: #{doctor.first_name} #{doctor.last_name}
Appointment ID: #{appointment.id}
Status: #{appointment.status}
Starts At: #{appointment.starts_at}

Login as the patient and go to /dashboard.
Check the "Past" tab (or scroll down) to see the appointment.
You should see the "Appreciate Doctor" button.
=======================================================
""")
