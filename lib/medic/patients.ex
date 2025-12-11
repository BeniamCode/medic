defmodule Medic.Patients do
  @moduledoc """
  The Patients context for managing patient profiles.
  """
  use Ash.Domain

  resources do
    resource Medic.Patients.Patient
  end

  alias Medic.Repo
  alias Medic.Patients.Patient

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
end
