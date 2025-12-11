defmodule Medic.Hospitals do
  @moduledoc """
  The Hospitals context.
  """

  use Ash.Domain

  resources do
    resource Medic.Hospitals.Hospital
    resource Medic.Hospitals.HospitalSchedule
  end

  import Ecto.Query, warn: false
  alias Medic.Repo

  alias Medic.Hospitals.Hospital

  @doc """
  Returns the list of hospitals.

  ## Examples

      iex> list_hospitals()
      [%Hospital{}, ...]

  """
  def list_hospitals do
    Repo.all(Hospital)
  end

  @doc """
  Gets a single hospital.

  Raises `Ecto.NoResultsError` if the Hospital does not exist.

  ## Examples

      iex> get_hospital!(123)
      %Hospital{}

      iex> get_hospital!(456)
      ** (Ecto.NoResultsError)

  """
  def get_hospital!(id), do: Repo.get!(Hospital, id)

  @doc """
  Creates a hospital.

  ## Examples

      iex> create_hospital(%{field: value})
      {:ok, %Hospital{}}

      iex> create_hospital(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_hospital(attrs \\ %{}) do
    %Hospital{}
    |> Hospital.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  @doc """
  Updates a hospital.

  ## Examples

      iex> update_hospital(hospital, %{field: new_value})
      {:ok, %Hospital{}}

      iex> update_hospital(hospital, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_hospital(%Hospital{} = hospital, attrs) do
    hospital
    |> Hospital.changeset(attrs)
    |> Repo.update(returning: true)
  end

  @doc """
  Deletes a hospital.

  ## Examples

      iex> delete_hospital(hospital)
      {:ok, %Hospital{}}

      iex> delete_hospital(hospital)
      {:error, %Ecto.Changeset{}}

  """
  def delete_hospital(%Hospital{} = hospital) do
    Repo.delete(hospital)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking hospital changes.

  ## Examples

      iex> change_hospital(hospital)
      %Ecto.Changeset{data: %Hospital{}}

  """
  def change_hospital(%Hospital{} = hospital, attrs \\ %{}) do
    Hospital.changeset(hospital, attrs)
  end

  def get_hospital_by_name(name) do
    Repo.get_by(Hospital, name: name)
  end

  alias Medic.Hospitals.HospitalSchedule

  @doc """
  Returns the list of hospital_schedules.

  ## Examples

      iex> list_hospital_schedules()
      [%HospitalSchedule{}, ...]

  """
  def list_hospital_schedules do
    Repo.all(HospitalSchedule)
  end

  @doc """
  Gets a single hospital_schedule.

  Raises `Ecto.NoResultsError` if the Hospital schedule does not exist.

  ## Examples

      iex> get_hospital_schedule!(123)
      %HospitalSchedule{}

      iex> get_hospital_schedule!(456)
      ** (Ecto.NoResultsError)

  """
  def get_hospital_schedule!(id), do: Repo.get!(HospitalSchedule, id)

  def get_schedule(hospital_id, date) do
    Repo.get_by(HospitalSchedule, hospital_id: hospital_id, date: date)
  end

  def list_on_duty_hospitals(date) do
    Repo.all(
      from h in Hospital,
        join: s in assoc(h, :hospital_schedules),
        where: s.date == ^date,
        preload: [hospital_schedules: s]
    )
  end

  @doc """
  Creates a hospital_schedule.

  ## Examples

      iex> create_hospital_schedule(%{field: value})
      {:ok, %HospitalSchedule{}}

      iex> create_hospital_schedule(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_hospital_schedule(attrs \\ %{}) do
    %HospitalSchedule{}
    |> HospitalSchedule.changeset(attrs)
    |> Repo.insert(returning: true)
  end

  @doc """
  Updates a hospital_schedule.

  ## Examples

      iex> update_hospital_schedule(hospital_schedule, %{field: new_value})
      {:ok, %HospitalSchedule{}}

      iex> update_hospital_schedule(hospital_schedule, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_hospital_schedule(%HospitalSchedule{} = hospital_schedule, attrs) do
    hospital_schedule
    |> HospitalSchedule.changeset(attrs)
    |> Repo.update(returning: true)
  end

  @doc """
  Deletes a hospital_schedule.

  ## Examples

      iex> delete_hospital_schedule(hospital_schedule)
      {:ok, %HospitalSchedule{}}

      iex> delete_hospital_schedule(hospital_schedule)
      {:error, %Ecto.Changeset{}}

  """
  def delete_hospital_schedule(%HospitalSchedule{} = hospital_schedule) do
    Repo.delete(hospital_schedule)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking hospital_schedule changes.

  ## Examples

      iex> change_hospital_schedule(hospital_schedule)
      %Ecto.Changeset{source: %HospitalSchedule{}}

  """
  def change_hospital_schedule(%HospitalSchedule{} = hospital_schedule, attrs \\ %{}) do
    HospitalSchedule.changeset(hospital_schedule, attrs)
  end
end
