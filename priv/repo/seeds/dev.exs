# Development Seeds - Realistic test data for development
# Run with: mix run priv/repo/seeds/dev.exs
# Requires Faker: {:faker, "~> 0.18", only: [:dev, :test]}

alias Medic.Repo
alias Medic.Accounts
alias Medic.Accounts.User
alias Medic.Doctors
alias Medic.Doctors.{Doctor, Specialty}
alias Medic.Patients
alias Medic.Patients.Patient
alias Medic.Appointments
alias Medic.Appointments.Appointment

# First run production seeds to ensure specialties exist
Code.require_file("prod.exs", __DIR__)

IO.puts("\n🧪 Seeding development data...")

# Greek cities with coordinates
greek_cities = [
  %{city: "Αθήνα", lat: 37.9838, lng: 23.7275},
  %{city: "Θεσσαλονίκη", lat: 40.6401, lng: 22.9444},
  %{city: "Πάτρα", lat: 38.2466, lng: 21.7346},
  %{city: "Ηράκλειο", lat: 35.3387, lng: 25.1442},
  %{city: "Λάρισα", lat: 39.6390, lng: 22.4191},
  %{city: "Βόλος", lat: 39.3666, lng: 22.9507},
  %{city: "Ιωάννινα", lat: 39.6650, lng: 20.8537},
  %{city: "Χανιά", lat: 35.5138, lng: 24.0180}
]

# Greek first names
greek_first_names = [
  "Γιώργος", "Νίκος", "Δημήτρης", "Κώστας", "Γιάννης",
  "Μαρία", "Ελένη", "Κατερίνα", "Αναστασία", "Σοφία",
  "Αλέξανδρος", "Μιχάλης", "Παναγιώτης", "Χρήστος", "Αντώνης",
  "Βασιλική", "Αικατερίνη", "Παναγιώτα", "Ευαγγελία", "Δήμητρα"
]

# Greek last names
greek_last_names = [
  "Παπαδόπουλος", "Αντωνίου", "Γεωργίου", "Νικολάου", "Δημητρίου",
  "Παπαδάκης", "Κωνσταντίνου", "Ιωάννου", "Βασιλείου", "Αλεξίου",
  "Οικονόμου", "Καραγιάννης", "Μακρής", "Παπανικολάου", "Σπυρόπουλος"
]

# Helper to generate Greek phone numbers
defmodule DevSeeds do
  def greek_phone, do: "69#{:rand.uniform(99_999_999) |> Integer.to_string() |> String.pad_leading(8, "0")}"
  
  def random_item(list), do: Enum.random(list)
  
  def random_bio(specialty_name) do
    years = Enum.random(5..30)
    """
    Ειδικός #{specialty_name} με #{years} χρόνια εμπειρίας. 
    Απόφοιτος Ιατρικής Σχολής του Πανεπιστημίου Αθηνών. 
    Μέλος της Ελληνικής Ιατρικής Εταιρείας.
    """
  end
end

# Get all specialties
specialties = Doctors.list_specialties()

IO.puts("\n👨‍⚕️ Creating demo doctors...")

# Create 20 demo doctors
doctors_created =
  for i <- 1..20 do
    first_name = DevSeeds.random_item(greek_first_names)
    last_name = DevSeeds.random_item(greek_last_names)
    email = "doctor#{i}@demo.medic.gr"
    specialty = DevSeeds.random_item(specialties)
    location = DevSeeds.random_item(greek_cities)
    is_verified = rem(i, 5) != 0  # 80% verified

    # Create user
    {:ok, user} =
      case Repo.get_by(User, email: email) do
        nil ->
          Accounts.register_user(%{
            "email" => email,
            "password" => "DemoPassword123!",
            "role" => "doctor"
          })
        existing ->
          {:ok, existing}
      end

    # Create or update doctor profile
    case Doctors.get_doctor_by_user_id(user.id) do
      nil ->
        # Insert with basic changeset
        {:ok, doctor} =
          %Doctor{user_id: user.id}
          |> Doctor.changeset(%{
            first_name: first_name,
            last_name: last_name,
            specialty_id: specialty.id,
            bio_el: DevSeeds.random_bio(specialty.name_el),
            bio: "Specialist in #{specialty.name_en} with extensive experience.",
            city: location.city,
            address: "Λεωφ. #{DevSeeds.random_item(["Αλεξάνδρας", "Συγγρού", "Κηφισίας", "Βουλιαγμένης"])} #{:rand.uniform(200)}",
            location_lat: location.lat + (:rand.uniform() - 0.5) * 0.1,
            location_lng: location.lng + (:rand.uniform() - 0.5) * 0.1,
            consultation_fee: Decimal.new(Enum.random([30, 40, 50, 60, 80, 100])),
            cal_com_username: if(rem(i, 3) == 0, do: "demo-doctor-#{i}", else: nil)
          })
          |> Repo.insert()
        
        # Update rating and review_count separately
        {:ok, doctor} =
          doctor
          |> Doctor.rating_changeset(%{
            rating: (3.5 + :rand.uniform() * 1.5) |> Float.round(1),
            review_count: :rand.uniform(150)
          })
          |> Repo.update()
        
        # Verify if needed
        doctor =
          if is_verified do
            {:ok, verified} = Doctors.verify_doctor(doctor)
            verified
          else
            doctor
          end
        
        IO.puts("  ✓ Dr. #{first_name} #{last_name} (#{specialty.name_el})#{if is_verified, do: " ✔", else: ""}")
        doctor

      existing ->
        IO.puts("  • Dr. #{existing.first_name} #{existing.last_name} exists")
        existing
    end
  end

IO.puts("\n👤 Creating demo patients...")

# Create 10 demo patients
patients_created =
  for i <- 1..10 do
    first_name = DevSeeds.random_item(greek_first_names)
    last_name = DevSeeds.random_item(greek_last_names)
    email = "patient#{i}@demo.medic.gr"

    # Create user
    {:ok, user} =
      case Repo.get_by(User, email: email) do
        nil ->
          Accounts.register_user(%{
            "email" => email,
            "password" => "DemoPassword123!",
            "role" => "patient"
          })
        existing ->
          {:ok, existing}
      end

    # Create patient profile
    case Patients.get_patient_by_user_id(user.id) do
      nil ->
        {:ok, patient} =
          %Patient{user_id: user.id}
          |> Patient.changeset(%{
            first_name: first_name,
            last_name: last_name,
            phone: DevSeeds.greek_phone(),
            date_of_birth: Date.new!(1960 + :rand.uniform(40), :rand.uniform(12), :rand.uniform(28))
          })
          |> Repo.insert()
        
        IO.puts("  ✓ #{first_name} #{last_name}")
        patient

      existing ->
        IO.puts("  • #{existing.first_name} #{existing.last_name} exists")
        existing
    end
  end

IO.puts("\n📅 Creating demo appointments...")

# Filter verified doctors (those with verified_at set)
verified_doctors = 
  doctors_created
  |> Enum.filter(fn d -> d.verified_at != nil end)

if Enum.empty?(verified_doctors) do
  IO.puts("  ⚠ No verified doctors found, skipping appointments")
else
  for patient <- Enum.take(patients_created, 5) do
    doctor = DevSeeds.random_item(verified_doctors)
    
    # Past appointment (completed) - use seed_changeset to bypass future validation
    past_start = DateTime.utc_now() |> DateTime.add(-Enum.random(1..30), :day) |> DateTime.truncate(:second)
    past_end = DateTime.add(past_start, 30 * 60, :second)
    
    case Repo.get_by(Appointment, patient_id: patient.id, doctor_id: doctor.id, status: "completed") do
      nil ->
        {:ok, _} =
          %Appointment{}
          |> Appointment.seed_changeset(%{
            patient_id: patient.id,
            doctor_id: doctor.id,
            starts_at: past_start,
            ends_at: past_end,
            duration_minutes: 30,
            status: "completed",
            appointment_type: "in_person"
          })
          |> Repo.insert()
        IO.puts("  ✓ Past: #{patient.first_name} → Dr. #{doctor.last_name}")
      _ ->
        IO.puts("  • Past appointment exists")
    end

    # Future appointment (confirmed)
    future_start = DateTime.utc_now() |> DateTime.add(Enum.random(1..14), :day) |> DateTime.truncate(:second)
    future_end = DateTime.add(future_start, 30 * 60, :second)
    doctor2 = DevSeeds.random_item(verified_doctors)

    case Repo.get_by(Appointment, patient_id: patient.id, doctor_id: doctor2.id, status: "confirmed") do
      nil ->
        {:ok, _} =
          %Appointment{}
          |> Appointment.changeset(%{
            patient_id: patient.id,
            doctor_id: doctor2.id,
            starts_at: future_start,
            ends_at: future_end,
            duration_minutes: 30,
            status: "confirmed",
            appointment_type: Enum.random(["in_person", "telemedicine"])
          })
          |> Repo.insert()
        IO.puts("  ✓ Future: #{patient.first_name} → Dr. #{doctor2.last_name}")
      _ ->
        IO.puts("  • Future appointment exists")
    end
  end
end

IO.puts("""

✅ Development seeding complete!

📧 Demo Accounts:
   Doctors: doctor1@demo.medic.gr ... doctor20@demo.medic.gr
   Patients: patient1@demo.medic.gr ... patient10@demo.medic.gr
   Password: DemoPassword123!
""")
