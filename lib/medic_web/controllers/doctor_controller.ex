defmodule MedicWeb.DoctorController do
  use MedicWeb, :controller

  alias Ash
  alias Decimal
  alias Medic.Appointments
  alias Medic.Doctors.Specialty
  alias Medic.Doctors.Doctor
  alias Medic.Appreciate.DoctorAppreciationStat
  alias Medic.Patients
  alias Medic.Repo
  alias Medic.Scheduling
  alias MedicWeb.I18n
  alias MedicWeb.ErrorHTML

  def show(conn, %{"id" => id} = params) do
    locale = conn.assigns[:locale] || I18n.default_locale()

    start_date =
      case Map.get(params, "date") do
        nil -> Date.utc_today()
        d -> Date.from_iso8601!(d)
      end

    case fetch_doctor(id) do
      {:ok, doctor} ->
        formatted = format_doctor(doctor, locale)
        page_title = formatted.full_name
        appreciation_stats = Repo.get(DoctorAppreciationStat, doctor.id)
        availability = Scheduling.get_slots_for_range(doctor, start_date, Date.add(start_date, 6))

        conn
        |> assign(:page_title, page_title)
        |> assign_prop(:doctor, formatted)
        |> assign_prop(:appreciation, appreciation_props(appreciation_stats))
        |> assign_prop(:availability, Enum.map(availability, &availability_props/1))
        # Pass current start date to frontend for pagination logic
        |> assign_prop(:startDate, Date.to_iso8601(start_date))
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

  def book(conn, %{"id" => doctor_id, "booking" => booking_params}) do
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

  defp fetch_patient(nil), do: {:error, :not_patient}

  defp fetch_patient(%{id: user_id} = user) do
    case Patients.get_patient_by_user_id(user_id) do
      nil -> maybe_create_patient_profile(user)
      patient -> {:ok, patient}
    end
  end

  defp maybe_create_patient_profile(%{role: role} = user)
       when role in ["patient", "doctor", "admin"] do
    attrs = inferred_patient_attrs(user)

    case Patients.create_patient(user, attrs) do
      {:ok, patient} -> {:ok, patient}
      {:error, changeset} -> {:error, changeset}
    end
  end

  defp maybe_create_patient_profile(_user), do: {:error, :not_patient}

  defp inferred_patient_attrs(user) do
    {first_name, last_name} =
      case {Map.get(user, :first_name), Map.get(user, :last_name)} do
        {first, last} when is_binary(first) and is_binary(last) -> {first, last}
        _ -> derive_names_from_email(user.email)
      end

    %{
      first_name: first_name || "Guest",
      last_name: last_name || "Patient"
    }
  end

  defp derive_names_from_email(nil), do: {"Guest", "Patient"}

  defp derive_names_from_email(email) do
    email
    |> String.split("@")
    |> List.first()
    |> to_string()
    |> String.replace(~r/[^a-zA-Z]/, " ")
    |> String.split(" ", trim: true)
    |> case do
      [first, last | _] -> {format_name_segment(first), format_name_segment(last)}
      [single] -> {format_name_segment(single), "Patient"}
      _ -> {"Guest", "Patient"}
    end
  end

  defp format_name_segment(name) do
    name
    |> String.downcase()
    |> String.capitalize()
  end

  defp parse_slot_params(%{"starts_at" => start_iso, "ends_at" => end_iso}) do
    with {:ok, starts_at, _offset} <- DateTime.from_iso8601(start_iso),
         {:ok, ends_at, _offset} <- DateTime.from_iso8601(end_iso) do
      {:ok,
       %{
         starts_at: DateTime.truncate(starts_at, :second),
         ends_at: DateTime.truncate(ends_at, :second)
       }}
    else
      _ -> {:error, :invalid_slot}
    end
  end

  defp create_booking(doctor, patient, slot, params) do
    consultation_mode =
      Map.get(params, "consultation_mode") ||
        Map.get(params, "appointment_type") ||
        "in_person"

    Appointments.create_appointment(%{
      doctor_id: doctor.id,
      patient_id: patient.id,
      starts_at: slot.starts_at,
      ends_at: slot.ends_at,
      consultation_mode_snapshot: consultation_mode,
      notes: Map.get(params, "notes")
    })
  end

  defp booking_error_message(:not_patient),
    do: dgettext("default", "Please complete patient onboarding")

  defp booking_error_message(:invalid_slot), do: dgettext("default", "Invalid time slot")

  defp booking_error_message(:slot_already_booked),
    do: dgettext("default", "This slot is no longer available")

  defp booking_error_message(%Ecto.Changeset{} = changeset) do
    errors =
      Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
        Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
          opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
        end)
      end)

    errors
    |> Enum.map(fn {k, v} -> "#{Phoenix.Naming.humanize(k)} #{Enum.join(v, ", ")}" end)
    |> Enum.join(". ")
  end

  defp booking_error_message(reason) do
    IO.inspect(reason, label: "Booking Error")
    dgettext("default", "Unable to book appointment")
  end

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
        if(doctor.next_available_slot,
          do: DateTime.to_iso8601(doctor.next_available_slot),
          else: nil
        )
    }
  end

  defp appreciation_props(nil) do
    %{
      totalDistinctPatients: 0,
      last30dDistinctPatients: 0,
      lastAppreciatedAt: nil
    }
  end

  defp appreciation_props(stats) do
    %{
      totalDistinctPatients: stats.appreciated_total_distinct_patients,
      last30dDistinctPatients: stats.appreciated_last_30d_distinct_patients,
      lastAppreciatedAt:
        stats.last_appreciated_at && DateTime.to_iso8601(stats.last_appreciated_at)
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
