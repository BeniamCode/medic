defmodule Medic.Appointments do
  @moduledoc """
  The Appointments context for managing bookings.
  """

  import Ecto.Query
  alias Medic.Repo
  alias Medic.Appointments.Appointment
  alias Medic.Notifications
  alias Medic.Doctors

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
    query = from a in Appointment, order_by: [desc: a.starts_at]

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
      where: a.starts_at > ^now,
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
  Gets an appointment with preloaded associations.
  """
  def get_appointment_with_details!(id) do
    Appointment
    |> Repo.get!(id)
    |> Repo.preload([:patient, doctor: [:specialty]])
  end

  @doc """
  Creates an appointment.
  The PostgreSQL exclusion constraint will reject double-bookings.
  """
  def create_appointment(attrs \\ %{}) do
    result = %Appointment{}
    |> Appointment.changeset(attrs)
    |> Repo.insert()
    |> handle_constraint_error()

    case result do
      {:ok, appointment} ->
        notify_doctor_booking(appointment)
        {:ok, appointment}
      error -> error
    end
  end

  defp notify_doctor_booking(appointment) do
    # Preload patient and doctor to get names and user_id
    appointment = Repo.preload(appointment, [:patient, :doctor])
    
    if appointment.doctor do
      Notifications.create_notification(%{
        user_id: appointment.doctor.user_id,
        type: "booking",
        title: "New Appointment Request",
        message: "Patient #{appointment.patient.first_name} #{appointment.patient.last_name} has requested an appointment.",
        resource_id: appointment.id,
        resource_type: "appointment"
      })
    end
  end

  @doc """
  Creates an appointment with starts_at and duration (calculates ends_at).
  """
  def create_appointment_with_duration(attrs) do
    starts_at = attrs[:starts_at] || attrs["starts_at"]
    duration = attrs[:duration_minutes] || attrs["duration_minutes"] || 30

    ends_at =
      if starts_at do
        DateTime.add(starts_at, duration * 60, :second)
      end

    attrs
    |> Map.put(:ends_at, ends_at)
    |> create_appointment()
  end

  @doc """
  Updates an appointment.
  """
  def update_appointment(%Appointment{} = appointment, attrs) do
    appointment
    |> Appointment.changeset(attrs)
    |> Repo.update()
    |> handle_constraint_error()
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
    result = appointment
    |> Appointment.cancel_changeset(reason)
    |> Repo.update()

    case result do
      {:ok, updated_appointment} ->
        notify_doctor_cancellation(updated_appointment)
        {:ok, updated_appointment}
      error -> error
    end
  end

  defp notify_doctor_cancellation(appointment) do
    # Preload patient and doctor
    appointment = Repo.preload(appointment, [:patient, :doctor])
    
    if appointment.doctor do
      Notifications.create_notification(%{
        user_id: appointment.doctor.user_id,
        type: "cancellation",
        title: "Appointment Cancelled",
        message: "Appointment with #{appointment.patient.first_name} #{appointment.patient.last_name} has been cancelled.",
        resource_id: appointment.id,
        resource_type: "appointment"
      })
    end
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
      where: a.starts_at > ^now,
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
      where: a.starts_at >= ^today_start,
      where: a.starts_at < ^today_end,
      order_by: a.starts_at,
      preload: [:patient]
    )
    |> Repo.all()
  end

  # Handle exclusion constraint violations gracefully
  defp handle_constraint_error({:ok, appointment}), do: {:ok, appointment}
  defp handle_constraint_error({:error, %Ecto.Changeset{} = changeset}) do
    if has_constraint_error?(changeset, :no_double_bookings) do
      {:error, :slot_already_booked}
    else
      {:error, changeset}
    end
  end

  defp has_constraint_error?(changeset, constraint_name) do
    Enum.any?(changeset.errors, fn
      {_field, {_msg, opts}} ->
        Keyword.get(opts, :constraint) == constraint_name
      _ ->
        false
    end)
  end
end
