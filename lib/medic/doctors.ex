defmodule Medic.Doctors do
  @moduledoc """
  The Doctors context for managing doctor profiles and specialties.
  """

  use Ash.Domain

  resources do
    resource Medic.Doctors.Doctor
    resource Medic.Doctors.Specialty
    resource Medic.Doctors.Review
    resource Medic.Doctors.Location
    resource Medic.Doctors.LocationRoom
    resource Medic.Doctors.ExperienceSubmission
    resource Medic.Doctors.PatientContext
  end

  alias Medic.Doctors.ExperienceSubmission
  require Decimal


  def get_doctor_experience_profile(doctor_id) do
    import Ecto.Query

    query =
      from s in ExperienceSubmission,
        where: s.doctor_id == ^doctor_id,
        select: %{
          communication_style: avg(s.communication_style),
          explanation_style: avg(s.explanation_style),
          personality_tone: avg(s.personality_tone),
          pace: avg(s.pace),
          appointment_timing: avg(s.appointment_timing),
          consultation_style: avg(s.consultation_style),
          count: count(s.id)
        }

    case Medic.Repo.one(query) do
      nil -> nil
      %{count: 0} -> nil
      stats -> 
        # Convert Decimals/Floats to rounded integers
        stats
        |> Map.new(fn {k, v} -> 
           val = 
             cond do
               k == :count -> v
               Decimal.is_decimal(v) -> Decimal.to_float(v)
               is_float(v) -> v
               is_integer(v) -> v / 1
               true -> 0.0
             end
           {k, round(val)} 
        end)
    end
  end

  import Ecto.Query
  alias Ecto.Changeset
  alias Medic.Repo
  alias Medic.Doctors.{Doctor, Specialty, Location, LocationRoom, PatientContext}
  alias Medic.Appointments.Appointment
  alias Medic.Workers.IndexDoctor
  require Ash.Query

  # --- Patient Context ---
  @doc """
  Lists distinct patients seen by a doctor with aggregate stats.
  """
  def list_my_patients(doctor_id) do
    # Get comprehensive patient stats from appointments
    query = 
      from a in Appointment,
        join: p in assoc(a, :patient),
        where: a.doctor_id == ^doctor_id,
        where: a.status in ["completed", "confirmed"],
        group_by: [
          p.id, 
          p.first_name, 
          p.last_name, 
          p.phone, 
          p.date_of_birth,
          p.profile_image_url
        ],
        select: %{
          patient_id: p.id,
          first_name: p.first_name,
          last_name: p.last_name,
          phone: p.phone,
          date_of_birth: p.date_of_birth,
          profile_image_url: p.profile_image_url,
          visit_count: count(a.id),
          last_visit: max(a.starts_at),
          first_visit: min(a.starts_at)
        }

    visits = Repo.all(query)

    # Get contexts
    patient_ids = Enum.map(visits, & &1.patient_id)
    
    contexts = 
      if patient_ids == [] do
        %{}
      else
        PatientContext
        |> Ash.Query.filter(doctor_id == ^doctor_id and patient_id in ^patient_ids)
        |> Ash.read!()
        |> Map.new(&{&1.patient_id, &1})
      end

    # Merge and calculate age
    Enum.map(visits, fn visit -> 
      visit
      |> Map.put(:context, Map.get(contexts, visit.patient_id))
      |> Map.put(:age, calculate_age(visit.date_of_birth))
    end)
    |> Enum.sort_by(& &1.last_visit, {:desc, DateTime})
  end

  defp calculate_age(nil), do: nil
  defp calculate_age(dob) do
    today = Date.utc_today()
    years = today.year - dob.year
    if Date.compare(Date.new!(today.year, dob.month, dob.day), today) == :gt do
      years - 1
    else
      years
    end
  end

  def get_patient_context(doctor_id, patient_id) do
    PatientContext
    |> Ash.Query.filter(doctor_id == ^doctor_id and patient_id == ^patient_id)
    |> Ash.read_one()
    |> case do
      {:ok, context} -> context
      _ -> nil
    end
  end

  def update_patient_context(doctor_id, patient_id, attrs) do
    case get_patient_context(doctor_id, patient_id) do
      nil ->
        PatientContext
        |> Ash.Changeset.for_create(:create, Map.merge(attrs, %{"doctor_id" => doctor_id, "patient_id" => patient_id}))
        |> Ash.create()
      
      context ->
        context
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()
    end
  end

  # --- Specialties ---

  @doc """
  Returns the list of specialties.
  """
  def list_specialties do
    Repo.all(from s in Specialty, order_by: s.name_en)
  end

  # --- Locations ---

  @doc """
  Lists a doctor's locations ordered by primary flag.
  """
  def list_locations(doctor_id) do
    Location
    |> Ash.Query.filter(doctor_id == ^doctor_id)
    |> Ash.Query.sort(desc: :is_primary, asc: :inserted_at)
    |> Ash.read!()
  end

  def get_location!(id), do: Ash.get!(Location, id)

  def create_location(attrs) do
    Location
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def update_location(%Location{} = location, attrs) do
    location
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  def delete_location(%Location{} = location), do: Ash.destroy(location)

  # --- Rooms ---

  def list_rooms(location_id) do
    LocationRoom
    |> Ash.Query.filter(doctor_location_id == ^location_id)
    |> Ash.read!()
  end

  def create_room(attrs) do
    LocationRoom
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def update_room(%LocationRoom{} = room, attrs) do
    room
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  def delete_room(%LocationRoom{} = room), do: Ash.destroy(room)

  @doc """
  Gets a single specialty by ID.
  """
  def get_specialty!(id), do: Repo.get!(Specialty, id)

  @doc """
  Gets a specialty by slug.
  """
  def get_specialty_by_slug(slug) do
    Repo.get_by(Specialty, slug: slug)
  end

  @doc """
  Creates a specialty.
  """
  def create_specialty(attrs \\ %{}) do
    %Specialty{}
    |> Specialty.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  @doc """
  Updates a specialty.
  """
  def update_specialty(%Specialty{} = specialty, attrs) do
    specialty
    |> Specialty.changeset(attrs)
    |> Repo.update(returning: true)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking specialty changes.
  """
  def change_specialty(%Specialty{} = specialty, attrs \\ %{}) do
    Specialty.changeset(specialty, attrs)
  end

  # --- Doctors ---

  @doc """
  Returns the list of doctors.

  ## Options
    * `:preload` - list of associations to preload
    * `:specialty_id` - filter by specialty
    * `:city` - filter by city
    * `:available_today` - filter to only doctors with availability today
    * `:verified` - filter to only verified doctors
  """
  def list_doctors(opts \\ []) do
    query = from d in Doctor, order_by: [desc: d.rating]

    query
    |> maybe_filter_specialty(opts[:specialty_id])
    |> maybe_filter_city(opts[:city])
    |> maybe_filter_available_today(opts[:available_today])
    |> maybe_filter_verified(opts[:verified])
    |> Repo.all()
    |> Ash.load!(opts[:preload] || [])
  end

  defp maybe_filter_specialty(query, nil), do: query

  defp maybe_filter_specialty(query, specialty_id) do
    from d in query, where: d.specialty_id == ^specialty_id
  end

  defp maybe_filter_city(query, nil), do: query

  defp maybe_filter_city(query, city) do
    from d in query, where: d.city == ^city
  end

  defp maybe_filter_available_today(query, true) do
    today_start = DateTime.utc_now() |> DateTime.truncate(:second)
    today_end = today_start |> DateTime.add(24 * 60 * 60, :second)

    from d in query,
      where: not is_nil(d.next_available_slot),
      where: d.next_available_slot >= ^today_start,
      where: d.next_available_slot < ^today_end
  end

  defp maybe_filter_available_today(query, _), do: query

  defp maybe_filter_verified(query, true) do
    from d in query, where: not is_nil(d.verified_at)
  end

  defp maybe_filter_verified(query, _), do: query

  @doc """
  Gets a single doctor.

  Raises `Ecto.NoResultsError` if the Doctor does not exist.
  """
  def get_doctor!(id), do: Repo.get!(Doctor, id)

  @doc """
  Gets a doctor by user_id.
  """
  def get_doctor_by_user_id(user_id) do
    Repo.get_by(Doctor, user_id: user_id)
  end

  @doc """
  Gets a doctor with preloaded associations.
  """
  def get_doctor_with_details!(id) do
    Doctor
    |> Repo.get!(id)
    |> Ash.load!([:specialty, :user])
  end

  @doc """
  Creates a doctor profile for a user.
  """
  def create_doctor(user, attrs \\ %{}) do
    attrs = maybe_geocode(attrs)

    %Doctor{}
    |> Doctor.changeset(attrs)
    |> Changeset.put_change(:user_id, user.id)
    |> Repo.insert(returning: true)
    |> tap(fn
      {:ok, doctor} -> enqueue_index_job(doctor)
      _ -> :ok
    end)
  end

  @doc """
  Updates a doctor.
  """
  def update_doctor(%Doctor{} = doctor, attrs) do
    attrs = maybe_geocode(attrs, doctor)

    doctor
    |> Doctor.changeset(attrs)
    |> Repo.update(returning: true)
    |> tap(fn
      {:ok, updated} -> enqueue_index_job(updated)
      _ -> :ok
    end)
  end

  defp maybe_geocode(attrs, doctor \\ nil) do
    # Normalize keys to strings
    attrs = Map.new(attrs, fn {k, v} -> {to_string(k), v} end)
    
    # Determine full address
    address = attrs["address"] || (doctor && doctor.address)
    zip_code = attrs["zip_code"] || (doctor && doctor.zip_code)
    city = attrs["city"] || (doctor && doctor.city)
    neighborhood = attrs["neighborhood"] || (doctor && doctor.neighborhood)

    # Check if manual coordinates provided
    manual_coords? = 
      (attrs["location_lat"] && attrs["location_lng"]) || 
      (is_float(attrs["location_lat"]) && is_float(attrs["location_lng"]))

    # Check if we should run geocoding
    # 1. New doctor (doctor == nil) and has address
    # 2. Existing doctor and address/city/zip/neighborhood changing AND manual coords NOT provided
    # 3. Existing doctor has address but no coords (backfill) AND manual coords NOT provided
    should_run? = 
      if manual_coords? do
        false
      else
        if doctor do
          (attrs["address"] && attrs["address"] != doctor.address) ||
          (attrs["zip_code"] && attrs["zip_code"] != doctor.zip_code) ||
          (attrs["city"] && attrs["city"] != doctor.city) ||
          (attrs["neighborhood"] && attrs["neighborhood"] != doctor.neighborhood) ||
          (address && (is_nil(doctor.location_lat) || is_nil(doctor.location_lng)))
        else
          address && city
        end
      end

    if should_run? && address do
      case Medic.Geocoding.geocode_address(address, city || "", zip_code, neighborhood) do
        {:ok, {lat, lng}} ->
          require Logger
          Logger.info("Geocoding success: #{lat}, #{lng}")
          Map.merge(attrs, %{"location_lat" => lat, "location_lng" => lng})
        _ ->
          attrs
      end
    else
      attrs
    end
  end

  @doc """
  Updates the doctor's next available slot (called by Oban job).
  """
  def update_next_available_slot(%Doctor{} = doctor, slot) do
    doctor
    |> Doctor.availability_changeset(%{next_available_slot: slot})
    |> Repo.update(returning: true)
  end

  @doc """
  Verifies a doctor.
  """
  def verify_doctor(%Doctor{} = doctor) do
    doctor
    |> Doctor.verify_changeset()
    |> Repo.update(returning: true)
    |> tap(fn
      {:ok, verified} -> enqueue_index_job(verified)
      _ -> :ok
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking doctor changes.
  """
  def change_doctor(%Doctor{} = doctor, attrs \\ %{}) do
    Doctor.changeset(doctor, attrs)
  end

  def enqueue_index_job(%Doctor{id: id}) do
    %{doctor_id: id}
    |> IndexDoctor.new()
    |> Oban.insert()
  end

  @doc """
  Searches doctors near a location within a given radius (km).
  Uses Haversine formula approximation for SQLite compatibility.
  """
  def list_doctors_near(lat, lng, radius_km \\ 10) do
    # Approximate degrees per km
    lat_range = radius_km / 111.0
    lng_range = radius_km / (111.0 * :math.cos(lat * :math.pi() / 180))

    from(d in Doctor,
      where: d.location_lat >= ^(lat - lat_range),
      where: d.location_lat <= ^(lat + lat_range),
      where: d.location_lng >= ^(lng - lng_range),
      where: d.location_lng <= ^(lng + lng_range),
      where: not is_nil(d.verified_at),
      order_by: [desc: d.rating]
    )
    |> Repo.all()
  end
end
