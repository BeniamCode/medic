defmodule Medic.Doctors do
  @moduledoc """
  The Doctors context for managing doctor profiles and specialties.
  """

  use Ash.Domain

  resources do
    resource Medic.Doctors.Doctor
    resource Medic.Doctors.Specialty
    resource Medic.Doctors.Review
  end

  import Ecto.Query
  alias Medic.Repo
  alias Medic.Doctors.{Doctor, Specialty}
  alias Medic.Search

  # --- Specialties ---

  @doc """
  Returns the list of specialties.
  """
  def list_specialties do
    Repo.all(from s in Specialty, order_by: s.name_en)
  end

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
    result =
      %Doctor{}
      |> Doctor.changeset(attrs)
      |> Ecto.Changeset.put_change(:user_id, user.id)
      |> Repo.insert(returning: true)

    case result do
      {:ok, doctor} ->
        Search.index_doctor(doctor)
        {:ok, doctor}

      error ->
        error
    end
  end

  @doc """
  Updates a doctor.
  """
  def update_doctor(%Doctor{} = doctor, attrs) do
    result =
      doctor
      |> Doctor.changeset(attrs)
      |> Repo.update(returning: true)

    case result do
      {:ok, updated_doctor} ->
        Search.index_doctor(updated_doctor)
        {:ok, updated_doctor}

      error ->
        error
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
    result =
      doctor
      |> Doctor.verify_changeset()
      |> Repo.update(returning: true)

    case result do
      {:ok, verified_doctor} ->
        Search.index_doctor(verified_doctor)
        {:ok, verified_doctor}

      error ->
        error
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking doctor changes.
  """
  def change_doctor(%Doctor{} = doctor, attrs \\ %{}) do
    Doctor.changeset(doctor, attrs)
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
