defmodule MedicWeb.DoctorProfileController do
  use MedicWeb, :controller

  alias Medic.Doctors
  alias Medic.Doctors.Doctor
  alias Medic.Doctors.Specialty

  def show(conn, _params) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user) do
      specialties = Doctors.list_specialties()

      conn
      |> assign(:page_title, dgettext("default", "Doctor Profile"))
      |> assign_prop(:doctor, doctor_props(doctor))
      |> assign_prop(:specialties, Enum.map(specialties, &specialty_option/1))
      |> render_inertia("Doctor/Profile")
    else
      _ -> redirect(conn, to: ~p"/doctor")
    end
  end

  def update(conn, %{"doctor" => doctor_params}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         result <- Doctors.update_doctor(doctor, map_input_arrays(doctor_params)) do
      case result do
        {:ok, _updated} ->
          conn
          |> put_flash(:success, dgettext("default", "Profile updated"))
          |> redirect(to: ~p"/dashboard/doctor/profile")

        {:error, changeset} ->
          conn
          |> put_status(:unprocessable_entity)
          |> assign_prop(:errors, errors_from_changeset(changeset))
          |> show(%{})
      end
    else
      _ -> redirect(conn, to: ~p"/dashboard/doctor/profile")
    end
  end

  defp fetch_doctor(user) do
    case Doctors.get_doctor_by_user_id(user.id) do
      nil -> {:error, :not_found}
      doctor -> {:ok, Ash.load!(doctor, [:specialty])}
    end
  end

  defp doctor_props(doctor) do
    %{
      id: doctor.id,
      first_name: doctor.first_name,
      last_name: doctor.last_name,
      title: doctor.title,
      pronouns: doctor.pronouns,
      academic_title: doctor.academic_title,
      hospital_affiliation: doctor.hospital_affiliation,
      registration_number: doctor.registration_number,
      years_of_experience: doctor.years_of_experience,
      specialty_id: doctor.specialty_id,
      specialty_name: doctor.specialty && doctor.specialty.name_en,
      bio: doctor.bio,
      bio_el: doctor.bio_el,
      address: doctor.address,
      city: doctor.city,
      telemedicine_available: doctor.telemedicine_available,
      consultation_fee: doctor.consultation_fee && Decimal.to_float(doctor.consultation_fee),
      board_certifications: doctor.board_certifications || [],
      languages: doctor.languages || [],
      insurance_networks: doctor.insurance_networks || [],
      sub_specialties: doctor.sub_specialties || [],
      clinical_procedures: doctor.clinical_procedures || [],
      conditions_treated: doctor.conditions_treated || []
    }
  end

  defp specialty_option(%Specialty{id: id, name_en: name_en}) do
    %{id: id, name: name_en}
  end

  defp map_input_arrays(params) do
    params
    |> Map.update("board_certifications", [], &comma_split/1)
    |> Map.update("languages", [], &comma_split/1)
    |> Map.update("insurance_networks", [], &comma_split/1)
    |> Map.update("sub_specialties", [], &comma_split/1)
    |> Map.update("clinical_procedures", [], &comma_split/1)
    |> Map.update("conditions_treated", [], &comma_split/1)
    |> update_decimal("consultation_fee")
  end

  defp comma_split(value) when is_binary(value) do
    value
    |> String.split([",", "\n"], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp comma_split(value) when is_list(value), do: value
  defp comma_split(_), do: []

  defp update_decimal(params, field) do
    case Map.get(params, field) do
      nil -> params
      "" -> Map.put(params, field, nil)
      value -> Map.put(params, field, Decimal.new(value))
    end
  end

  defp errors_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
