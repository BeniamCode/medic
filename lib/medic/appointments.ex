defmodule Medic.Appointments do
  @moduledoc """
  The Appointments context for managing bookings.
  """

  import Ecto.Query
  alias Medic.Repo
  alias Medic.Appointments.Appointment

  @doc """
  Returns the list of appointments.

  ## Options
    * `:patient_id` - filter by patient
    * `:doctor_id` - filter by doctor
    * `:status` - filter by status
    * `:upcoming` - filter to only upcoming appointments
    * `:preload` - list of associations to preload
  """
  def list_appointments(opts \\ []) do
    query = from a in Appointment, order_by: [desc: a.scheduled_at]

    query
    |> maybe_filter_patient(opts[:patient_id])
    |> maybe_filter_doctor(opts[:doctor_id])
    |> maybe_filter_status(opts[:status])
    |> maybe_filter_upcoming(opts[:upcoming])
    |> maybe_preload(opts[:preload])
    |> Repo.all()
  end

  defp maybe_filter_patient(query, nil), do: query
  defp maybe_filter_patient(query, patient_id) do
    from a in query, where: a.patient_id == ^patient_id
  end

  defp maybe_filter_doctor(query, nil), do: query
  defp maybe_filter_doctor(query, doctor_id) do
    from a in query, where: a.doctor_id == ^doctor_id
  end

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status) when is_list(status) do
    from a in query, where: a.status in ^status
  end
  defp maybe_filter_status(query, status) do
    from a in query, where: a.status == ^status
  end

  defp maybe_filter_upcoming(query, true) do
    now = DateTime.utc_now()
    from a in query,
      where: a.scheduled_at > ^now,
      where: a.status in ["pending", "confirmed"]
  end
  defp maybe_filter_upcoming(query, _), do: query

  defp maybe_preload(query, nil), do: query
  defp maybe_preload(query, preloads), do: from(q in query, preload: ^preloads)

  @doc """
  Gets a single appointment.

  Raises `Ecto.NoResultsError` if the Appointment does not exist.
  """
  def get_appointment!(id), do: Repo.get!(Appointment, id)

  @doc """
  Gets an appointment by Cal.com UID.
  """
  def get_appointment_by_cal_uid(uid) do
    Repo.get_by(Appointment, cal_com_uid: uid)
  end

  @doc """
  Gets an appointment with preloaded associations.
  """
  def get_appointment_with_details!(id) do
    Appointment
    |> Repo.get!(id)
    |> Repo.preload([:patient, :doctor])
  end

  @doc """
  Creates an appointment.
  """
  def create_appointment(attrs \\ %{}) do
    %Appointment{}
    |> Appointment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates an appointment from a Cal.com booking.
  """
  def create_appointment_from_cal_com(doctor_id, patient_id, cal_data) do
    attrs = %{
      doctor_id: doctor_id,
      patient_id: patient_id,
      scheduled_at: cal_data["startTime"],
      duration_minutes: cal_data["length"] || 30,
      cal_com_booking_id: to_string(cal_data["id"]),
      cal_com_uid: cal_data["uid"],
      meeting_url: cal_data["meetingUrl"],
      appointment_type: if(cal_data["meetingUrl"], do: "telemedicine", else: "in_person"),
      status: "confirmed"
    }

    %Appointment{}
    |> Appointment.changeset(attrs)
    |> Appointment.cal_com_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an appointment.
  """
  def update_appointment(%Appointment{} = appointment, attrs) do
    appointment
    |> Appointment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Confirms an appointment.
  """
  def confirm_appointment(%Appointment{} = appointment) do
    appointment
    |> Appointment.confirm_changeset()
    |> Repo.update()
  end

  @doc """
  Completes an appointment.
  """
  def complete_appointment(%Appointment{} = appointment) do
    appointment
    |> Appointment.complete_changeset()
    |> Repo.update()
  end

  @doc """
  Cancels an appointment.
  """
  def cancel_appointment(%Appointment{} = appointment, reason \\ nil) do
    appointment
    |> Appointment.cancel_changeset(reason)
    |> Repo.update()
  end

  @doc """
  Marks an appointment as no-show.
  """
  def mark_no_show(%Appointment{} = appointment) do
    appointment
    |> Appointment.no_show_changeset()
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking appointment changes.
  """
  def change_appointment(%Appointment{} = appointment, attrs \\ %{}) do
    Appointment.changeset(appointment, attrs)
  end

  @doc """
  Deletes an appointment.
  """
  def delete_appointment(%Appointment{} = appointment) do
    Repo.delete(appointment)
  end

  @doc """
  Gets the count of upcoming appointments for a doctor.
  """
  def count_upcoming_doctor_appointments(doctor_id) do
    now = DateTime.utc_now()

    from(a in Appointment,
      where: a.doctor_id == ^doctor_id,
      where: a.scheduled_at > ^now,
      where: a.status in ["pending", "confirmed"],
      select: count(a.id)
    )
    |> Repo.one()
  end

  @doc """
  Gets today's appointments for a doctor.
  """
  def list_doctor_appointments_today(doctor_id) do
    today_start = Date.utc_today() |> DateTime.new!(~T[00:00:00], "Etc/UTC")
    today_end = DateTime.add(today_start, 24 * 60 * 60, :second)

    from(a in Appointment,
      where: a.doctor_id == ^doctor_id,
      where: a.scheduled_at >= ^today_start,
      where: a.scheduled_at < ^today_end,
      order_by: a.scheduled_at,
      preload: [:patient]
    )
    |> Repo.all()
  end
end
