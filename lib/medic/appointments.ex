defmodule Medic.Appointments do
  @moduledoc """
  The Appointments context for managing bookings.
  """

  use Ash.Domain

  resources do
    resource Medic.Appointments.Appointment
    resource Medic.Appointments.AppointmentType
    resource Medic.Appointments.AppointmentTypeLocation
    resource Medic.Appointments.AppointmentEvent
    resource Medic.Appointments.AppointmentResourceClaim
  end

  import Ecto.Query
  alias Medic.Repo

  alias Medic.Appointments.{
    Appointment,
    AppointmentEvent,
    AppointmentResourceClaim,
    AppointmentType,
    AppointmentTypeLocation
  }

  alias Medic.Notifications
  alias Medic.Workers.{AppointmentHoldExpiry, AppointmentPendingExpiry}
  alias Phoenix.PubSub
  alias Oban
  require Ash.Query

  @default_hold_seconds 5 * 60
  @default_pending_seconds 24 * 60 * 60
  @default_reminder_offsets_seconds [-86_400, -7_200]

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
    |> Repo.all()
    |> Ash.load!(opts[:preload] || [])
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
    |> Ash.load!([:patient, doctor: [:specialty]])
  end

  # --- Appointment Types ---

  def list_appointment_types(doctor_id, opts \\ []) do
    include_inactive = Keyword.get(opts, :include_inactive, false)

    AppointmentType
    |> Ash.Query.filter(doctor_id == ^doctor_id)
    |> maybe_filter_inactive(include_inactive)
    |> Ash.Query.sort(asc: :name)
    |> Ash.read!()
  end

  defp maybe_filter_inactive(query, true), do: query

  defp maybe_filter_inactive(query, _false) do
    Ash.Query.filter(query, is_active == true)
  end

  def get_appointment_type!(id), do: Ash.get!(AppointmentType, id)

  def create_appointment_type(attrs) do
    AppointmentType
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def update_appointment_type(%AppointmentType{} = type, attrs) do
    type
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  def delete_appointment_type(%AppointmentType{} = type), do: Ash.destroy(type)

  def upsert_type_location(attrs) do
    AppointmentTypeLocation
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  # --- Appointment Events ---

  def log_event(appointment_id, action, metadata \\ %{}, actor \\ %{}) do
    attrs =
      actor
      |> Map.take([:actor_type, :actor_id])
      |> Map.merge(%{
        appointment_id: appointment_id,
        occurred_at: DateTime.utc_now() |> DateTime.truncate(:second),
        action: action,
        metadata: metadata
      })

    AppointmentEvent
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  # --- Lifecycle Actions ---

  @doc """
  Place a temporary hold on a slot. Optionally accepts :hold_expires_at and :bookable_resource_id.
  """
  def hold_slot(attrs) when is_map(attrs) do
    Repo.transaction(fn ->
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      hold_expires_at =
        Map.get(attrs, :hold_expires_at) ||
          Map.get(attrs, "hold_expires_at") ||
          DateTime.add(now, @default_hold_seconds, :second)

      appointment_attrs =
        attrs
        |> Map.new()
        |> Map.put(:status, "held")
        |> Map.put(:hold_expires_at, hold_expires_at)

      with {:ok, appointment} <- create_appointment_record(appointment_attrs),
           :ok <- maybe_claim_resource(attrs, appointment),
           :ok <- schedule_hold_expiry(appointment) do
        log_event(appointment.id, "held_created", %{hold_expires_at: hold_expires_at})
        broadcast_doctor_event(appointment.doctor_id, :refresh_dashboard)
        appointment
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Doctor proposes a new time; appointment becomes pending and patient must approve.
  """
  def reschedule_request(appointment_or_id, %DateTime{} = new_starts_at, actor \\ %{}) do
    Repo.transaction(fn ->
      appointment = load_for_transition(appointment_or_id)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      duration_minutes =
        appointment.service_duration_snapshot || appointment.duration_minutes || 30

      new_ends_at = DateTime.add(new_starts_at, duration_minutes * 60, :second)
      pending_expires_at = DateTime.add(now, @default_pending_seconds, :second)

      {:ok, updated} =
        appointment
        |> Ash.Changeset.for_update(:update, %{
          starts_at: new_starts_at,
          ends_at: new_ends_at,
          status: "pending",
          pending_expires_at: pending_expires_at,
          approval_required_snapshot: true,
          rescheduled_from_appointment_id:
            appointment.rescheduled_from_appointment_id || appointment.id
        })
        |> Ash.update()

      log_event(
        updated.id,
        "reschedule_requested",
        %{
          previous_starts_at: appointment.starts_at,
          new_starts_at: new_starts_at
        },
        actor
      )

      schedule_pending_expiry(updated)
      maybe_enqueue_pending_notifications(updated)
      broadcast_doctor_event(updated.doctor_id, :refresh_dashboard)
      updated
    end)
  end

  @doc """
  Move held appointment to confirmed (auto-approve path).
  """
  def confirm_booking(appointment_or_id) do
    Repo.transaction(fn ->
      appointment = load_for_transition(appointment_or_id)
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      cond do
        appointment.status != "held" ->
          Repo.rollback(:invalid_state)

        appointment.hold_expires_at && DateTime.compare(appointment.hold_expires_at, now) != :gt ->
          Repo.rollback(:hold_expired)

        true ->
          {:ok, updated} =
            appointment
            |> Ash.Changeset.for_update(:update, %{status: "confirmed", pending_expires_at: nil})
            |> Ash.update()

          log_event(updated.id, "confirmed")
          schedule_default_reminders(updated)
          maybe_enqueue_confirmation_notifications(updated)
          broadcast_doctor_event(updated.doctor_id, :refresh_dashboard)
          updated
      end
    end)
  end

  @doc """
  Move held appointment to pending (doctor approval path).
  """
  def submit_request(appointment_or_id, opts \\ []) do
    Repo.transaction(fn ->
      appointment = load_for_transition(appointment_or_id)
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      pending_ttl_seconds = Keyword.get(opts, :pending_ttl_seconds, @default_pending_seconds)

      pending_expires_at =
        Keyword.get(opts, :pending_expires_at) || DateTime.add(now, pending_ttl_seconds, :second)

      cond do
        appointment.status != "held" ->
          Repo.rollback(:invalid_state)

        appointment.hold_expires_at && DateTime.compare(appointment.hold_expires_at, now) != :gt ->
          Repo.rollback(:hold_expired)

        true ->
          {:ok, updated} =
            appointment
            |> Ash.Changeset.for_update(:update, %{
              status: "pending",
              pending_expires_at: pending_expires_at,
              approval_required_snapshot: true
            })
            |> Ash.update()

          case schedule_pending_expiry(updated) do
            :ok ->
              log_event(updated.id, "request_submitted", %{pending_expires_at: pending_expires_at})

              maybe_enqueue_pending_notifications(updated)

              broadcast_doctor_event(updated.doctor_id, :refresh_dashboard)
              updated

            {:error, reason} ->
              Repo.rollback(reason)
          end
      end
    end)
  end

  @doc """
  Doctor approves a pending request.
  """
  def approve_request(appointment_or_id, actor \\ %{}) do
    Repo.transaction(fn ->
      appointment = load_for_transition(appointment_or_id)

      if appointment.status != "pending" do
        Repo.rollback(:invalid_state)
      end

      {:ok, updated} =
        appointment
        |> Ash.Changeset.for_update(:update, %{status: "confirmed", pending_expires_at: nil})
        |> Ash.update()

      log_event(updated.id, "approved", %{}, actor)
      schedule_default_reminders(updated)
      maybe_enqueue_confirmation_notifications(updated)
      broadcast_doctor_event(updated.doctor_id, :refresh_dashboard)
      updated
    end)
  end

  @doc """
  Doctor rejects a pending request.
  """
  def reject_request(appointment_or_id, reason \\ nil, actor \\ %{}) do
    Repo.transaction(fn ->
      appointment = load_for_transition(appointment_or_id)

      if appointment.status != "pending" do
        Repo.rollback(:invalid_state)
      end

      now = DateTime.utc_now() |> DateTime.truncate(:second)

      {:ok, updated} =
        appointment
        |> Ash.Changeset.for_update(:update, %{
          status: "cancelled",
          cancelled_at: now,
          cancellation_reason: reason,
          cancelled_by_actor_type: Map.get(actor, :actor_type),
          cancelled_by_actor_id: Map.get(actor, :actor_id)
        })
        |> Ash.update()

      release_claims(updated.id)
      log_event(updated.id, "rejected", %{reason: reason}, actor)
      broadcast_doctor_event(updated.doctor_id, :refresh_dashboard)
      updated
    end)
  end

  @doc """
  Mark appointment complete.
  """
  def complete_appointment(%Appointment{} = appointment) do
    appointment
    |> Appointment.complete_changeset()
    |> Repo.update(returning: true)
  end

  @doc """
  Mark appointment no-show.
  """
  def mark_no_show(%Appointment{} = appointment) do
    appointment
    |> Appointment.no_show_changeset()
    |> Repo.update(returning: true)
  end

  defp load_for_transition(%Appointment{} = appointment), do: appointment
  defp load_for_transition(id), do: get_appointment!(id)

  defp create_appointment_record(attrs) do
    Appointment
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  defp maybe_claim_resource(attrs, appointment) do
    resource_id = Map.get(attrs, :bookable_resource_id) || Map.get(attrs, "bookable_resource_id")

    if is_nil(resource_id) do
      :ok
    else
      AppointmentResourceClaim
      |> Ash.Changeset.for_create(:create, %{
        appointment_id: appointment.id,
        bookable_resource_id: resource_id,
        starts_at: appointment.starts_at,
        ends_at: appointment.ends_at,
        status: "active"
      })
      |> Ash.create()
      |> case do
        {:ok, _claim} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end
  end

  defp schedule_hold_expiry(%Appointment{hold_expires_at: nil}), do: :ok

  defp schedule_hold_expiry(%Appointment{id: id, hold_expires_at: hold_expires_at}) do
    %{"appointment_id" => id}
    |> AppointmentHoldExpiry.new(schedule_at: hold_expires_at)
    |> Oban.insert()
    |> case do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp schedule_pending_expiry(%Appointment{pending_expires_at: nil}), do: :ok

  defp schedule_pending_expiry(%Appointment{id: id, pending_expires_at: pending_expires_at}) do
    %{"appointment_id" => id}
    |> AppointmentPendingExpiry.new(schedule_at: pending_expires_at)
    |> Oban.insert()
    |> case do
      {:ok, _job} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end

  defp release_claims(appointment_id) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    with {:ok, claims} <-
           AppointmentResourceClaim
           |> Ash.Query.filter(appointment_id == ^appointment_id and status == "active")
           |> Ash.read() do
      Enum.each(claims, fn claim ->
        claim
        |> Ash.Changeset.for_update(:update, %{status: "released", released_at: now})
        |> Ash.update()

        :ok
      end)
    end

    :ok
  rescue
    _ -> :ok
  end

  defp schedule_default_reminders(%Appointment{starts_at: nil}), do: :ok

  defp schedule_default_reminders(%Appointment{} = appointment) do
    appointment = Ash.load!(appointment, [:patient, :doctor])
    now = DateTime.utc_now()

    Enum.each(@default_reminder_offsets_seconds, fn offset_seconds ->
      reminder_at = DateTime.add(appointment.starts_at, offset_seconds, :second)

      if DateTime.compare(reminder_at, now) == :gt do
        base_payload = %{
          type: "booking",
          title: "Appointment reminder",
          message: "You have an upcoming appointment.",
          resource_id: appointment.id,
          resource_type: "appointment"
        }

        if appointment.patient && appointment.patient.user_id do
          Notifications.enqueue_notification_job(%{
            user_id: appointment.patient.user_id,
            template: "appointment_reminder_patient",
            payload: base_payload,
            scheduled_at: reminder_at
          })
        end

        if appointment.doctor && appointment.doctor.user_id do
          Notifications.enqueue_notification_job(%{
            user_id: appointment.doctor.user_id,
            template: "appointment_reminder_doctor",
            payload: base_payload,
            scheduled_at: reminder_at
          })
        end
      end
    end)

    :ok
  rescue
    _ -> :ok
  end

  defp maybe_enqueue_confirmation_notifications(appointment) do
    appointment = Ash.load!(appointment, [:patient, :doctor])

    base_payload = %{
      type: "booking",
      title: "Appointment confirmed",
      message: "Your appointment is confirmed.",
      resource_id: appointment.id,
      resource_type: "appointment"
    }

    if appointment.patient && appointment.patient.user_id do
      Notifications.enqueue_notification_job(%{
        user_id: appointment.patient.user_id,
        template: "appointment_confirmed_patient",
        payload: base_payload
      })
    end

    if appointment.doctor && appointment.doctor.user_id do
      Notifications.enqueue_notification_job(%{
        user_id: appointment.doctor.user_id,
        template: "appointment_confirmed_doctor",
        payload: base_payload
      })
    end

    :ok
  rescue
    _ -> :ok
  end

  defp maybe_enqueue_pending_notifications(appointment) do
    appointment = Ash.load!(appointment, [:doctor])

    if appointment.doctor && appointment.doctor.user_id do
      Notifications.enqueue_notification_job(%{
        user_id: appointment.doctor.user_id,
        template: "appointment_pending_review",
        payload: %{
          type: "booking",
          title: "New appointment request",
          message: "A patient submitted a booking request awaiting your approval.",
          resource_id: appointment.id,
          resource_type: "appointment"
        }
      })
    end

    :ok
  rescue
    _ -> :ok
  end

  @doc """
  Creates an appointment.
  The PostgreSQL exclusion constraint will reject double-bookings.
  """
  def create_appointment(attrs \\ %{}) do
    attrs =
      attrs
      |> Map.new()
      |> ensure_consultation_mode_snapshot()

    result =
      %Appointment{}
      |> Appointment.changeset(attrs)
      |> Repo.insert(returning: true)
      |> handle_constraint_error()

    case result do
      {:ok, appointment} ->
        notify_doctor_booking(appointment)
        broadcast_doctor_event(appointment.doctor_id, :refresh_dashboard)
        {:ok, appointment}

      error ->
        error
    end
  end

  defp notify_doctor_booking(appointment) do
    # Preload patient and doctor to get names and user_id
    appointment = Ash.load!(appointment, [:patient, :doctor])

    if appointment.doctor do
      Notifications.enqueue_notification_job(%{
        user_id: appointment.doctor.user_id,
        template: "appointment_request",
        payload: %{
          type: "booking",
          title: "New Appointment Request",
          message:
            "Patient #{appointment.patient.first_name} #{appointment.patient.last_name} has requested an appointment.",
          resource_id: appointment.id,
          resource_type: "appointment"
        }
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

  defp ensure_consultation_mode_snapshot(attrs) do
    cond do
      Map.has_key?(attrs, :consultation_mode_snapshot) ->
        attrs

      Map.has_key?(attrs, "consultation_mode_snapshot") ->
        attrs

      true ->
        mode =
          Map.get(attrs, :consultation_mode) ||
            Map.get(attrs, "consultation_mode") ||
            Map.get(attrs, :appointment_type) ||
            Map.get(attrs, "appointment_type") ||
            "in_person"

        Map.put(attrs, :consultation_mode_snapshot, mode)
    end
  end

  @doc """
  Updates an appointment.
  """
  def update_appointment(%Appointment{} = appointment, attrs) do
    appointment
    |> Appointment.changeset(attrs)
    |> Repo.update(returning: true)
    |> handle_constraint_error()
  end

  @doc """
  Confirms an appointment.
  """
  def confirm_appointment(%Appointment{} = appointment) do
    appointment
    |> Appointment.confirm_changeset()
    |> Repo.update(returning: true)
  end

  @doc """
  Cancels an appointment.

  Options:
    * `:cancelled_by` - identifies who triggered the cancellation (`:patient`, `:doctor`, or `:system`).
  """
  def cancel_appointment(%Appointment{} = appointment, reason \\ nil, opts \\ []) do
    result =
      appointment
      |> Appointment.cancel_changeset(reason)
      |> put_cancel_actor(opts)
      |> Repo.update(returning: true)

    case result do
      {:ok, updated_appointment} ->
        release_claims(updated_appointment.id)
        updated_appointment = Ash.load!(updated_appointment, [:patient, :doctor])
        maybe_notify_cancellation(updated_appointment, Keyword.get(opts, :cancelled_by, :patient))

        log_event(updated_appointment.id, "cancelled", %{reason: reason}, %{
          actor_type: Keyword.get(opts, :cancelled_by_actor_type),
          actor_id: Keyword.get(opts, :cancelled_by_actor_id)
        })

        broadcast_doctor_event(updated_appointment.doctor_id, :refresh_dashboard)
        {:ok, updated_appointment}

      error ->
        error
    end
  end

  defp maybe_notify_cancellation(appointment, :doctor) do
    notify_patient_cancellation(appointment)
  rescue
    _ -> :ok
  end

  defp maybe_notify_cancellation(appointment, :patient) do
    notify_doctor_cancellation(appointment)
  rescue
    _ -> :ok
  end

  defp maybe_notify_cancellation(_appointment, _), do: :ok

  defp put_cancel_actor(changeset, opts) do
    actor_type = opts |> Keyword.get(:cancelled_by_actor_type) |> normalize_actor_value()
    actor_id = Keyword.get(opts, :cancelled_by_actor_id)

    changeset
    |> maybe_put_change(:cancelled_by_actor_type, actor_type)
    |> maybe_put_change(:cancelled_by_actor_id, actor_id)
  end

  defp normalize_actor_value(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_actor_value(value), do: value

  defp maybe_put_change(changeset, _field, nil), do: changeset

  defp maybe_put_change(changeset, field, value),
    do: Ecto.Changeset.put_change(changeset, field, value)

  defp notify_doctor_cancellation(appointment) do
    if appointment.doctor && appointment.doctor.user_id && appointment.patient do
      Notifications.create_notification(%{
        user_id: appointment.doctor.user_id,
        type: "cancellation",
        title: "Appointment Cancelled",
        message:
          "Appointment with #{appointment.patient.first_name} #{appointment.patient.last_name} has been cancelled.",
        resource_id: appointment.id,
        resource_type: "appointment"
      })
    end

    :ok
  end

  defp notify_patient_cancellation(appointment) do
    if appointment.patient && appointment.patient.user_id && appointment.doctor do
      message =
        if appointment.cancellation_reason && appointment.cancellation_reason != "" do
          "Your appointment with Dr. #{appointment.doctor.last_name} was cancelled: #{appointment.cancellation_reason}"
        else
          "Your appointment with Dr. #{appointment.doctor.last_name} was cancelled."
        end

      Notifications.create_notification(%{
        user_id: appointment.patient.user_id,
        type: "cancellation",
        title: "Appointment Cancelled",
        message: message,
        resource_id: appointment.id,
        resource_type: "appointment"
      })
    end

    :ok
  end

  def subscribe_doctor_events(doctor_id) when not is_nil(doctor_id) do
    PubSub.subscribe(Medic.PubSub, doctor_topic(doctor_id))
  end

  def broadcast_doctor_event(nil, _event), do: :ok

  def broadcast_doctor_event(doctor_id, event, payload \\ %{}) do
    PubSub.broadcast(Medic.PubSub, doctor_topic(doctor_id), {event, payload})
  end

  defp doctor_topic(doctor_id), do: "doctor_events:#{doctor_id}"

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
      order_by: a.starts_at
    )
    |> Repo.all()
    |> Ash.load!([:patient, :appointment_type_record])
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
