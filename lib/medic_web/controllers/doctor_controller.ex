defmodule MedicWeb.DoctorController do
  use MedicWeb, :controller

  alias Ash
  alias Decimal
  alias Medic.Appointments
  alias Medic.Doctors
  alias Medic.Doctors.Specialty
  alias Medic.Doctors.Doctor
  alias Medic.Patients
  alias Medic.Repo
  alias Medic.Scheduling
  alias MedicWeb.I18n
  alias MedicWeb.ErrorHTML

  def show(conn, %{"id" => id}) do
    locale = conn.assigns[:locale] || I18n.default_locale()

    case fetch_doctor(id) do
      {:ok, doctor} ->
        formatted = format_doctor(doctor, locale)
        page_title = formatted.full_name
        availability = Scheduling.get_slots_for_range(doctor, Date.utc_today(), Date.add(Date.utc_today(), 7))

        conn
        |> assign(:page_title, page_title)
        |> assign_prop(:doctor, formatted)
        |> assign_prop(:availability, Enum.map(availability, &availability_props/1))
        |> render_inertia("Public/DoctorProfile")

      :error ->
        conn
        |> put_status(:not_found)
        |> put_view(ErrorHTML)
        |> render("404.html", layout: false)
    end
  end

  defp fetch_doctor(id) do
    Doctor
    |> Repo.get(id)
    |> case do
      %Doctor{} = doctor -> {:ok, Ash.load!(doctor, [:specialty])}
      nil -> :error
    end
  rescue
    _ -> :error
  end

  def book(conn, %{"doctor_id" => doctor_id, "booking" => booking_params}) do
    with {:ok, doctor} <- fetch_doctor(doctor_id),
         {:ok, patient} <- fetch_patient(conn.assigns.current_user),
         {:ok, slot} <- parse_slot_params(booking_params),
         {:ok, appointment} <- create_booking(doctor, patient, slot, booking_params) do
      conn
      |> put_flash(:success, dgettext("default", "Appointment requested"))
      |> redirect(to: ~p"/appointments/#{appointment.id}")
    else
      {:error, reason} ->
        conn
        |> put_flash(:error, booking_error_message(reason))
        |> redirect(to: ~p"/doctors/#{doctor_id}")
    end
  end

  defp fetch_patient(%{id: user_id}) do
    case Patients.get_patient_by_user_id(user_id) do
      nil -> {:error, :not_patient}
      patient -> {:ok, patient}
    end
  end

  defp parse_slot_params(%{"starts_at" => start_iso, "ends_at" => end_iso}) do
    with {:ok, starts_at, 0} <- DateTime.from_iso8601(start_iso),
         {:ok, ends_at, 0} <- DateTime.from_iso8601(end_iso) do
      {:ok, %{starts_at: starts_at, ends_at: ends_at}}
    else
      _ -> {:error, :invalid_slot}
    end
  end

  defp create_booking(doctor, patient, slot, params) do
    Appointments.create_appointment(%{
      doctor_id: doctor.id,
      patient_id: patient.id,
      starts_at: slot.starts_at,
      ends_at: slot.ends_at,
      appointment_type: Map.get(params, "appointment_type", "in_person"),
      notes: Map.get(params, "notes")
    })
  end

  defp booking_error_message(:not_patient), do: dgettext("default", "Please complete patient onboarding")
  defp booking_error_message(:invalid_slot), do: dgettext("default", "Invalid time slot")
  defp booking_error_message(_), do: dgettext("default", "Unable to book appointment")

  defp format_doctor(%Doctor{} = doctor, locale) do
    specialty = doctor.specialty

    %{
      id: doctor.id,
      full_name: Enum.join([doctor.first_name, doctor.last_name], " ") |> String.trim(),
      first_name: doctor.first_name,
      last_name: doctor.last_name,
      title: doctor.title,
      pronouns: doctor.pronouns,
      rating: doctor.rating,
      review_count: doctor.review_count,
      verified: not is_nil(doctor.verified_at),
      profile_image_url: doctor.profile_image_url,
      specialty:
        case specialty do
          %Specialty{} -> %{name: specialty.name_en, slug: specialty.slug}
          _ -> nil
        end,
      city: doctor.city,
      address: doctor.address,
      hospital_affiliation: doctor.hospital_affiliation,
      years_of_experience: doctor.years_of_experience,
      bio: localized_bio(doctor, locale),
      sub_specialties: doctor.sub_specialties || [],
      clinical_procedures: doctor.clinical_procedures || [],
      conditions_treated: doctor.conditions_treated || [],
      languages: doctor.languages || [],
      awards: doctor.awards || [],
      telemedicine_available: doctor.telemedicine_available,
      consultation_fee: doctor.consultation_fee && Decimal.to_float(doctor.consultation_fee),
      next_available_slot:
        if(doctor.next_available_slot, do: DateTime.to_iso8601(doctor.next_available_slot), else: nil)
    }
  end

  defp localized_bio(%Doctor{bio: bio, bio_el: bio_el}, locale) do
    case locale do
      "el" -> bio_el || bio
      _ -> bio || bio_el
    end
  end

  defp availability_props(%{date: date, slots: slots}) do
    %{
      date: Date.to_iso8601(date),
      slots:
        Enum.map(slots, fn slot ->
          %{
            starts_at: DateTime.to_iso8601(slot.starts_at),
            ends_at: DateTime.to_iso8601(slot.ends_at),
            status: slot.status
          }
        end)
    }
  end
end
