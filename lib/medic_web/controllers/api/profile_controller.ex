defmodule MedicWeb.API.ProfileController do
  @moduledoc """
  Profile API controller for mobile app.
  Handles viewing and updating user profiles (both doctor and patient).
  """
  use MedicWeb, :controller

  alias Medic.Doctors
  alias Medic.Patients
  alias Medic.Repo

  action_fallback MedicWeb.API.FallbackController

  @doc """
  GET /api/profile
  Returns the current user's profile (doctor or patient).
  """
  def show(conn, _params) do
    user = conn.assigns.current_user
    
    case user.role do
      "doctor" ->
        doctor = Doctors.get_doctor_by_user_id(user.id)
        if doctor do
          doctor = Ash.load!(doctor, [:specialty])
          conn
          |> put_status(:ok)
          |> json(%{data: doctor_profile_to_json(doctor)})
        else
          {:error, :not_found}
        end
      
      "patient" ->
        patient = Patients.get_patient_by_user_id(user.id)
        if patient do
          conn
          |> put_status(:ok)
          |> json(%{data: patient_profile_to_json(patient)})
        else
          {:error, :not_found}
        end
      
      _ ->
        {:error, :not_found}
    end
  end

  @doc """
  PUT /api/profile
  Updates the current user's profile.
  """
  def update(conn, params) do
    user = conn.assigns.current_user
    
    case user.role do
      "doctor" ->
        doctor = Doctors.get_doctor_by_user_id(user.id)
        if doctor do
          case Doctors.update_doctor(doctor, params) do
            {:ok, updated} ->
              updated = Ash.load!(updated, [:specialty])
              conn
              |> put_status(:ok)
              |> json(%{data: doctor_profile_to_json(updated)})
            
            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{errors: format_errors(changeset)})
          end
        else
          {:error, :not_found}
        end
      
      "patient" ->
        patient = Patients.get_patient_by_user_id(user.id)
        if patient do
          case Patients.update_patient(patient, params) do
            {:ok, updated} ->
              conn
              |> put_status(:ok)
              |> json(%{data: patient_profile_to_json(updated)})
            
            {:error, changeset} ->
              conn
              |> put_status(:unprocessable_entity)
              |> json(%{errors: format_errors(changeset)})
          end
        else
          {:error, :not_found}
        end
      
      _ ->
        {:error, :not_found}
    end
  end

  # --- Private Helpers ---

  defp doctor_profile_to_json(doctor) do
    %{
      id: doctor.id,
      first_name: doctor.first_name,
      last_name: doctor.last_name,
      bio: doctor.bio,
      profile_image_url: doctor.profile_image_url,
      city: doctor.city,
      address: doctor.address,
      zip_code: doctor.zip_code,
      phone: doctor.phone,
      consultation_fee: doctor.consultation_fee,
      telemedicine_available: doctor.telemedicine_available,
      years_of_experience: doctor.years_of_experience,
      verified: doctor.verified_at != nil,
      specialty: if(doctor.specialty, do: %{
        id: doctor.specialty.id,
        name: doctor.specialty.name_en,
        slug: doctor.specialty.slug
      }),
      languages: doctor.languages || [],
      sub_specialties: doctor.sub_specialties || [],
      rating: doctor.rating,
      review_count: doctor.review_count
    }
  end

  defp patient_profile_to_json(patient) do
    %{
      id: patient.id,
      first_name: patient.first_name,
      last_name: patient.last_name,
      email: patient.email,
      phone: patient.phone,
      date_of_birth: patient.date_of_birth,
      gender: patient.gender,
      profile_image_url: patient.profile_image_url,
      address: patient.address,
      city: patient.city,
      zip_code: patient.zip_code
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
