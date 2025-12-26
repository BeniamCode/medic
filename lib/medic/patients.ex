defmodule Medic.Patients do
  @moduledoc """
  The Patients context for managing patient profiles.
  """
  use Ash.Domain

  resources do
    resource Medic.Patients.Patient
    resource Medic.Patients.DoctorContext
  end

  alias Medic.Repo
  alias Medic.Patients.{Patient, DoctorContext}
  alias Medic.Appointments.Appointment
  import Ecto.Query
  require Ash.Query

  # --- Doctor Context ---
  @doc """
  Lists distinct doctors seen by a patient with aggregate stats.
  """
  def list_my_doctors(patient_id) do
    # Get comprehensive doctor stats from appointments
    query = 
      from a in Appointment,
        join: d in assoc(a, :doctor),
        left_join: s in assoc(d, :specialty),
        where: a.patient_id == ^patient_id,
        where: a.status in ["completed", "confirmed"],
        group_by: [
          d.id,
          d.first_name,
          d.last_name,
          d.profile_image_url,
          d.rating,
          s.id,
          s.name_en
        ],
        select: %{
          doctor_id: d.id,
          first_name: d.first_name,
          last_name: d.last_name,
          profile_image_url: d.profile_image_url,
          rating: d.rating,
          specialty: s.name_en,
          visit_count: count(a.id),
          last_visit: max(a.starts_at),
          first_visit: min(a.starts_at)
        }

    visits = Repo.all(query)

    # Get contexts
    doctor_ids = Enum.map(visits, & &1.doctor_id)
    
    contexts = 
      if doctor_ids == [] do
        %{}
      else
        DoctorContext
        |> Ash.Query.filter(patient_id == ^patient_id and doctor_id in ^doctor_ids)
        |> Ash.read!()
        |> Map.new(&{&1.doctor_id, &1})
      end

    # Merge
    Enum.map(visits, fn visit -> 
      Map.put(visit, :context, Map.get(contexts, visit.doctor_id))
    end)
    |> Enum.sort_by(& &1.last_visit, {:desc, DateTime})
  end

  def get_doctor_context(patient_id, doctor_id) do
    DoctorContext
    |> Ash.Query.filter(patient_id == ^patient_id and doctor_id == ^doctor_id)
    |> Ash.read_one()
    |> case do
      {:ok, context} -> context
      _ -> nil
    end
  end

  def update_doctor_context(patient_id, doctor_id, attrs) do
    case get_doctor_context(patient_id, doctor_id) do
      nil ->
        DoctorContext
        |> Ash.Changeset.for_create(:create, Map.merge(attrs, %{"patient_id" => patient_id, "doctor_id" => doctor_id}))
        |> Ash.create()
      
      context ->
        context
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()
    end
  end

  # --- Patient Functions ---

  @doc """
  Returns the list of patients.
  """
  def list_patients do
    Repo.all(Patient)
  end

  @doc """
  Gets a single patient.

  Raises `Ecto.NoResultsError` if the Patient does not exist.
  """
  def get_patient!(id), do: Repo.get!(Patient, id)

  @doc """
  Gets a patient by user_id.
  """
  def get_patient_by_user_id(user_id) do
    Repo.get_by(Patient, user_id: user_id)
  end

  @doc """
  Gets a patient with preloaded associations.
  """
  def get_patient_with_details!(id) do
    Patient
    |> Repo.get!(id)
    |> Ash.load!([:user, :appointments])
  end

  @doc """
  Creates a patient profile for a user.
  """
  def create_patient(user, attrs \\ %{}) do
    %Patient{}
    |> Patient.changeset(attrs)
    |> Ecto.Changeset.put_change(:user_id, user.id)
    |> Repo.insert(returning: true)
  end

  @doc """
  Updates a patient.
  """
  def update_patient(%Patient{} = patient, attrs) do
    patient
    |> Patient.changeset(attrs)
    |> Repo.update(returning: true)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking patient changes.
  """
  def change_patient(%Patient{} = patient, attrs \\ %{}) do
    Patient.changeset(patient, attrs)
  end

  @doc """
  Deletes a patient.
  """
  def delete_patient(%Patient{} = patient) do
    Repo.delete(patient)
  end

  # --- Calendar Booking Support ---

  @doc """
  Find a patient by email (exact match).
  """
  def get_patient_by_email(email) when is_binary(email) do
    email = String.downcase(email)

    # 1. Try to find by User email (Registered)
    registered =
      from(p in Patient,
        join: u in assoc(p, :user),
        where: u.email == ^email,
        limit: 1
      )
      |> Repo.one()

    case registered do
      %Patient{} = p ->
        p

      nil ->
        # 2. Try to find by Patient email (Unclaimed)
        Patient
        |> where([p], p.email == ^email)
        |> limit(1)
        |> Repo.one()
    end
  end

  def get_patient_by_email(_), do: nil

  @doc """
  Find a patient by phone number (exact match with normalization).
  """
  def get_patient_by_phone(phone) when is_binary(phone) do
    normalized = normalize_phone(phone)

    Patient
    |> where([p], fragment("regexp_replace(?, '[^0-9]', '', 'g') = ?", p.phone, ^normalized))
    |> limit(1)
    |> Repo.one()
  end

  def get_patient_by_phone(_), do: nil

  @doc """
  Search for patients by email OR phone.
  Returns list of matching patients (for conflict resolution).
  """
  def search_patients_by_contact(email, phone) do
    results = []

    results =
      if email && String.trim(email) != "" do
        case get_patient_by_email(email) do
          nil -> results
          patient -> [patient | results]
        end
      else
        results
      end

    results =
      if phone && String.trim(phone) != "" do
        case get_patient_by_phone(phone) do
          nil -> results
          patient -> [patient | results]
        end
      else
        results
      end

    results |> Enum.uniq_by(& &1.id)
  end

  @doc """
  Create a patient record marked as doctor-initiated (unclaimed).
  """
  def create_unclaimed_patient(attrs) do
    Patient
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.Changeset.force_change_attribute(:doctor_initiated, true)
    |> Ash.create()
  end

  defp normalize_phone(phone) do
    phone
    |> String.replace(~r/[^0-9]/, "")
  end
end
