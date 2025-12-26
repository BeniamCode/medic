# Development seeds - Creates 600 doctors with realistic distribution
#
# Run with: mix run priv/repo/seeds/dev.exs
# Or:       mix seed.dev

alias Medic.Repo
alias Medic.Accounts
alias Medic.Doctors
alias Medic.Doctors.{Doctor, Specialty}
alias Medic.Patients
alias Medic.Patients.Patient
alias Medic.Appointments.Appointment
alias Medic.MedicalTaxonomy
alias Medic.Scheduling

require Logger
import Ecto.Query

IO.puts("\n🏥 Starting development seed (600 doctors)...\n")

# --- Configuration ---

doctor_count = 600
patient_count = 50
demo_password = "DemoPassword123!"

# Greek cities with approximate populations (for weighted distribution)
cities = [
  %{name: "Athens", lat: 37.9838, lng: 23.7275, weight: 40},
  %{name: "Thessaloniki", lat: 40.6401, lng: 22.9444, weight: 15},
  %{name: "Patras", lat: 38.2466, lng: 21.7346, weight: 7},
  %{name: "Heraklion", lat: 35.3387, lng: 25.1442, weight: 6},
  %{name: "Larissa", lat: 39.6390, lng: 22.4191, weight: 5},
  %{name: "Volos", lat: 39.3666, lng: 22.9507, weight: 4},
  %{name: "Ioannina", lat: 39.6650, lng: 20.8537, weight: 4},
  %{name: "Chania", lat: 35.5138, lng: 24.0180, weight: 3},
  %{name: "Rhodes", lat: 36.4349, lng: 28.2176, weight: 3},
  %{name: "Alexandroupoli", lat: 40.8475, lng: 25.8743, weight: 2},
  %{name: "Kalamata", lat: 37.0389, lng: 22.1142, weight: 2},
  %{name: "Kavala", lat: 40.9397, lng: 24.4128, weight: 2},
  %{name: "Serres", lat: 41.0866, lng: 23.5497, weight: 2},
  %{name: "Corfu", lat: 39.6243, lng: 19.9217, weight: 2},
  %{name: "Mykonos", lat: 37.4467, lng: 25.3289, weight: 1},
  %{name: "Santorini", lat: 36.3932, lng: 25.4615, weight: 1},
  %{name: "Zakynthos", lat: 37.7879, lng: 20.8979, weight: 1}
]

# English first names (common)
first_names = ~w(
  Alexander Alexandra Andrew Anna Anthony Barbara Benjamin Catherine
  Charles Christina Christopher Daniel David Elizabeth Emily Emma
  George Helen James Jennifer John Jonathan Julia Katherine
  Margaret Maria Mark Matthew Michael Nicholas Patricia Paul
  Peter Rachel Rebecca Richard Robert Sarah Sophia Stephen
  Thomas Victoria William Jennifer Jessica Ashley Amanda Brittany
)

# English last names (common)
last_names = ~w(
  Anderson Brown Campbell Clark Davis Evans Garcia Green
  Hall Harris Jackson Johnson Jones King Lee Lewis
  Martin Martinez Miller Mitchell Moore Nelson Parker Perez
  Phillips Roberts Robinson Rodriguez Scott Smith Taylor Thomas
  Thompson Turner Walker White Williams Wilson Wright Young
)

# Specialty distribution (higher weight = more doctors)
specialty_weights = %{
  "general-practice" => 15,
  "internal-medicine" => 12,
  "family-medicine" => 10,
  "pediatrics" => 8,
  "cardiology" => 7,
  "orthopedics" => 7,
  "dermatology" => 6,
  "ophthalmology" => 6,
  "gynecology" => 6,
  "obgyn" => 5,
  "dentistry" => 8,
  "psychiatry" => 5,
  "neurology" => 4,
  "gastroenterology" => 4,
  "ent" => 4,
  "pulmonology" => 4,
  "endocrinology" => 3,
  "rheumatology" => 3,
  "nephrology" => 3,
  "urology" => 3,
  "oncology" => 3,
  "hematology" => 2,
  "allergy-immunology" => 2,
  "infectious-diseases" => 2,
  "radiology" => 3,
  "pathology" => 2,
  "anesthesiology" => 3,
  "emergency-medicine" => 3,
  "critical-care" => 2,
  "plastic-surgery" => 2,
  "general-surgery" => 4,
  "neurosurgery" => 2,
  "cardiac-surgery" => 1,
  "vascular-surgery" => 2,
  "thoracic-surgery" => 1,
  "orthopedic-surgery" => 3,
  "sports-medicine" => 2,
  "physical-rehab" => 3,
  "geriatrics" => 2,
  "palliative-medicine" => 1,
  "sleep-medicine" => 1,
  "optometry" => 2,
  "periodontology" => 2,
  "psychology" => 4
}

# --- Helper Functions ---

defmodule DevSeeds do
  def random_item(list), do: Enum.random(list)

  def weighted_random(items, weight_fn) do
    weighted_list =
      Enum.flat_map(items, fn item ->
        weight = weight_fn.(item)
        List.duplicate(item, weight)
      end)

    random_item(weighted_list)
  end

  def random_city(cities) do
    weighted_random(cities, fn city -> city.weight end)
  end

  def random_specialty_id(weights, specialties) do
    available_slugs = Enum.map(specialties, & &1.slug)

    weights
    |> Enum.filter(fn {slug, _} -> slug in available_slugs end)
    |> Enum.flat_map(fn {slug, weight} -> List.duplicate(slug, weight) end)
    |> case do
      [] -> Enum.random(available_slugs)
      list -> random_item(list)
    end
  end

  def random_rating do
    base = Enum.random(35..50) / 10.0
    Float.round(base, 1)
  end

  def random_review_count do
    case Enum.random(1..100) do
      n when n <= 50 -> Enum.random(0..20)
      n when n <= 80 -> Enum.random(20..100)
      n when n <= 95 -> Enum.random(100..300)
      _ -> Enum.random(300..1000)
    end
  end

  def random_fee do
    Enum.random([30, 40, 50, 60, 70, 80, 100, 120, 150, 200])
  end

  def random_bio(specialty_name) do
    years = Enum.random(5..30)
    hospitals = [
      "Athens General Hospital", "Thessaloniki Medical Center",
      "Evangelismos Hospital", "AHEPA University Hospital",
      "Hippocrates Hospital", "Metropolitan Hospital",
      "Hygeia Hospital", "Mediterraneo Hospital"
    ]
    certifications = [
      "American Board certified", "European Board certified",
      "Fellowship trained", "University accredited"
    ]

    """
    Experienced #{specialty_name} specialist with #{years} years of practice.
    Previously at #{random_item(hospitals)}. #{random_item(certifications)}.
    Committed to providing excellent patient care with a focus on modern treatment approaches.
    """
    |> String.trim()
  end

  def add_location_jitter(lat, lng) do
    lat_offset = (:rand.uniform() - 0.5) * 0.05
    lng_offset = (:rand.uniform() - 0.5) * 0.05
    {lat + lat_offset, lng + lng_offset}
  end
end

# --- Seed Specialties from Taxonomy (if not already done by prod.exs) ---

IO.puts("📋 Checking specialties...")

taxonomy_specialties = MedicalTaxonomy.specialties()

for spec <- taxonomy_specialties do
  case Doctors.get_specialty_by_slug(spec.id) do
    nil ->
      Doctors.create_specialty(%{
        name_en: spec.name,
        name_el: spec.name_el,
        slug: spec.id,
        icon: spec.icon
      })
    _ -> :ok
  end
end

# Get all specialties for doctor creation
all_specialties = Repo.all(from s in Specialty, select: s)
specialty_map = Map.new(all_specialties, fn s -> {s.slug, s} end)

IO.puts("  ✓ #{length(all_specialties)} specialties ready")

# --- Seed Doctors ---

IO.puts("\n👨‍⚕️ Seeding #{doctor_count} doctors...")

existing_doctor_count = Repo.one(from d in Doctor, select: count(d.id))
doctors_to_create = max(0, doctor_count - existing_doctor_count)

if doctors_to_create > 0 do
  for i <- 1..doctors_to_create do
    # Pick specialty based on weights
    specialty_slug = DevSeeds.random_specialty_id(specialty_weights, all_specialties)
    specialty = Map.get(specialty_map, specialty_slug) || Enum.random(all_specialties)

    # Pick city based on population
    city = DevSeeds.random_city(cities)
    {lat, lng} = DevSeeds.add_location_jitter(city.lat, city.lng)

    first_name = DevSeeds.random_item(first_names)
    last_name = DevSeeds.random_item(last_names)
    email = "doctor#{existing_doctor_count + i}@demo.medic.gr"

    # Create user (this creates a basic doctor profile via register_user callback)
    {:ok, user} =
      Accounts.register_user(%{
        email: email,
        password: demo_password,
        role: "doctor"
      })

    # Load the doctor profile created by register_user and UPDATE it
    user = Ash.load!(user, [:doctor])
    doctor = user.doctor
    
    # Update doctor with full profile details
    {:ok, doctor} =
      doctor
      |> Doctor.changeset(%{
        first_name: first_name,
        last_name: last_name,
        specialty_id: specialty.id,
        bio: DevSeeds.random_bio(specialty.name_en),
        city: city.name,
        address: "#{Enum.random(1..999)} Main Street, #{city.name}",
        location_lat: lat,
        location_lng: lng,
        consultation_fee: DevSeeds.random_fee()
      })
      |> Repo.update()

    # Verify 70% of doctors
    if Enum.random(1..100) <= 70 do
      {:ok, doctor} = Doctors.verify_doctor(doctor)

      # Update rating for verified doctors
      doctor
      |> Doctor.rating_changeset(%{
        rating: DevSeeds.random_rating(),
        review_count: DevSeeds.random_review_count()
      })
      |> Repo.update!()
    end

    if rem(i, 100) == 0 do
      IO.puts("  ... created #{existing_doctor_count + i} doctors")
    end
  end
else
  IO.puts("  • #{existing_doctor_count} doctors already exist, skipping creation")
end

total_doctors = Repo.one(from d in Doctor, select: count(d.id))
IO.puts("  ✓ #{total_doctors} doctors total")

# --- Seed Patients ---

IO.puts("\n🏃 Seeding #{patient_count} patients...")

existing_patient_count = Repo.one(from p in Patient, select: count(p.id))
patients_to_create = max(0, patient_count - existing_patient_count)

if patients_to_create > 0 do
  for i <- 1..patients_to_create do
    first_name = DevSeeds.random_item(first_names)
    last_name = DevSeeds.random_item(last_names)
    email = "patient#{existing_patient_count + i}@demo.medic.gr"

    {:ok, user} =
      Accounts.register_user(%{
        email: email,
        password: demo_password,
        role: "patient"
      })

    # Load the patient profile created by register_user and UPDATE it
    user = Ash.load!(user, [:patient])
    patient = user.patient
    
    # Update patient with full profile details
    patient
    |> Patient.changeset(%{
      first_name: first_name,
      last_name: last_name,
      phone: "+30 69#{:rand.uniform(99999999) |> Integer.to_string() |> String.pad_leading(8, "0")}",
      date_of_birth: Date.add(Date.utc_today(), -Enum.random(18..80) * 365)
    })
    |> Repo.update!()
  end
else
  IO.puts("  • #{existing_patient_count} patients already exist")
end

total_patients = Repo.one(from p in Patient, select: count(p.id))
IO.puts("  ✓ #{total_patients} patients total")

# --- Seed Sample Appointments ---

IO.puts("\n📅 Seeding sample appointments...")

verified_doctors =
  from(d in Doctor,
    where: not is_nil(d.verified_at),
    preload: [:user],
    limit: 100
  )
  |> Repo.all()

if Enum.empty?(verified_doctors) do
  IO.puts("  ⚠ No verified doctors found, skipping appointments")
else
  all_patients = Repo.all(from p in Patient, preload: [:user], limit: 20)

  for patient <- all_patients do
    doctor = DevSeeds.random_item(verified_doctors)

    # Past appointment (completed)
    past_start = DateTime.utc_now() |> DateTime.add(-Enum.random(1..30), :day) |> DateTime.truncate(:second)
    past_end = DateTime.add(past_start, 30 * 60, :second)

    case Repo.get_by(Appointment, patient_id: patient.id, doctor_id: doctor.id, status: "completed") do
      nil ->
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

      _ ->
        :exists
    end

    # Future appointment (confirmed)
    future_start = DateTime.utc_now() |> DateTime.add(Enum.random(1..14), :day) |> DateTime.truncate(:second)
    future_end = DateTime.add(future_start, 30 * 60, :second)
    doctor2 = DevSeeds.random_item(verified_doctors)

    case Repo.get_by(Appointment, patient_id: patient.id, doctor_id: doctor2.id, status: "confirmed") do
      nil ->
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

      _ ->
        :exists
    end
  end

  IO.puts("  ✓ Sample appointments created")
end

# --- Seed Availability Rules for Some Doctors ---

IO.puts("\n🗓️ Seeding availability rules...")

rules_created =
  verified_doctors
  |> Enum.take(50)
  |> Enum.map(fn doctor ->
    # Create rules for Monday-Friday
    for day <- 1..5 do
      case Repo.get_by(Medic.Scheduling.AvailabilityRule, doctor_id: doctor.id, day_of_week: day) do
        nil ->
          Scheduling.create_availability_rule(%{
            doctor_id: doctor.id,
            day_of_week: day,
            start_time: ~T[09:00:00],
            end_time: ~T[17:00:00],
            break_start: ~T[13:00:00],
            break_end: ~T[14:00:00],
            slot_duration_minutes: 30
          })
          :created

        _ ->
          :exists
      end
    end
  end)
  |> List.flatten()
  |> Enum.count(& &1 == :created)

IO.puts("  ✓ #{rules_created} availability rules created")

# --- Summary ---

IO.puts("""

✅ Development seeding complete!

📊 Statistics:
   Specialties: #{length(all_specialties)}
   Doctors: #{total_doctors}
   Patients: #{total_patients}

📧 Demo Accounts:
   Doctors:  doctor1@demo.medic.gr ... doctor#{total_doctors}@demo.medic.gr
   Patients: patient1@demo.medic.gr ... patient#{total_patients}@demo.medic.gr
   Password: #{demo_password}

🔍 Search Examples:
   - "heart" → Cardiology, Cardiac Surgery, etc.
   - "brain" → Neurology, Neurosurgery, Psychiatry
   - "stomach" → Gastroenterology
""")
