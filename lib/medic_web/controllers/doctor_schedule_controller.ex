defmodule MedicWeb.DoctorScheduleController do
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Doctors
  alias Medic.Scheduling

  def show(conn, _params) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user) do
      rules = Scheduling.list_schedule_rules_for_ui(doctor.id)

      exceptions = Scheduling.list_availability_exceptions(doctor.id, upcoming_only: true)

      upcoming =
        Appointments.list_appointments(
          doctor_id: doctor.id,
          upcoming: true,
          preload: [:patient]
        )

      conn
      |> assign(:page_title, dgettext("default", "Schedule"))
      |> assign_prop(:availability_rules, Enum.map(rules, &rule_props/1))

      mapped_exceptions = Enum.map(exceptions, &exception_props/1)
      IO.inspect(mapped_exceptions, label: "DEBUG EXCEPTIONS PROPS")

      conn
      |> assign(:page_title, dgettext("default", "Schedule"))
      |> assign_prop(:availability_rules, Enum.map(rules, &rule_props/1))

      mapped_exceptions = Enum.map(exceptions, &exception_props/1)

      conn
      |> assign(:page_title, dgettext("default", "Schedule"))
      |> assign_prop(:availability_rules, Enum.map(rules, &rule_props/1))
      |> assign_prop(:exceptions, mapped_exceptions)
      |> assign_prop(:upcoming_appointments, Enum.map(upcoming, &appointment_props/1))
      |> render_inertia("Doctor/Schedule")
    else
      _ -> redirect(conn, to: ~p"/dashboard/doctor")
    end
  end

  def update(conn, %{"rule" => rule_params}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         attrs <- normalize_rule_params(rule_params),
         {:ok, _} <- Scheduling.upsert_schedule_rule(doctor.id, attrs) do
      conn
      |> put_flash(:success, dgettext("default", "Availability saved"))
      |> redirect(to: ~p"/doctor/schedule")
    else
      _ ->
        conn
        |> put_flash(:error, dgettext("default", "Unable to save rule"))
        |> redirect(to: ~p"/doctor/schedule")
    end
  end

  def delete(conn, %{"id" => id}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, _} <- Scheduling.delete_schedule_rule(doctor.id, id) do
      conn
      |> put_flash(:success, dgettext("default", "Rule removed"))
      |> redirect(to: ~p"/doctor/schedule")
    else
      {:error, :not_found} ->
        fallback_delete_legacy(conn, id)

      _ ->
        conn
        |> put_flash(:error, dgettext("default", "Unable to delete rule"))
        |> redirect(to: ~p"/doctor/schedule")
    end
  end

  defp fallback_delete_legacy(conn, id) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, rule} <- fetch_rule(id, doctor.id),
         {:ok, _} <- Scheduling.delete_availability_rule(rule) do
      conn
      |> put_flash(:success, dgettext("default", "Rule removed"))
      |> redirect(to: ~p"/doctor/schedule")
    else
      _ ->
        conn
        |> put_flash(:error, dgettext("default", "Unable to delete rule"))
        |> redirect(to: ~p"/doctor/schedule")
    end
  end

  defp normalize_rule_params(params) do
    %{
      id: normalize_id(params["id"] || params[:id]),
      day_of_week: parse_integer(params["day_of_week"] || params[:day_of_week]),
      slot_duration_minutes:
        parse_integer(params["slot_duration_minutes"] || params[:slot_duration_minutes]) || 30,
      start_time: parse_time(params["start_time"] || params[:start_time]),
      end_time: parse_time(params["end_time"] || params[:end_time]),
      break_start: parse_time(params["break_start"] || params[:break_start]),
      break_end: parse_time(params["break_end"] || params[:break_end]),
      is_active: parse_boolean(params["is_active"] || params[:is_active])
    }
  end

  defp normalize_id(value) when value in [nil, ""], do: nil
  defp normalize_id(value), do: value

  defp parse_integer(value) when is_integer(value), do: value
  defp parse_integer(value) when is_float(value), do: round(value)

  defp parse_integer(value) when is_binary(value) do
    case Integer.parse(value) do
      {int, _} -> int
      _ -> nil
    end
  end

  defp parse_integer(_), do: nil

  defp parse_boolean(value) when value in [false, "false", 0, "0"], do: false
  defp parse_boolean(_), do: true

  defp parse_time(value) do
    value
    |> blank_to_nil_value()
    |> do_parse_time()
  end

  defp do_parse_time(nil), do: nil
  defp do_parse_time(%Time{} = time), do: time

  defp do_parse_time(value) when is_binary(value) do
    normalized =
      case String.split(value, ":") do
        [hour, minute] -> "#{hour}:#{minute}:00"
        _ -> value
      end

    case Time.from_iso8601(normalized) do
      {:ok, time} -> time
      _ -> nil
    end
  end

  defp do_parse_time(_), do: nil

  defp blank_to_nil_value(value) when value in [nil, ""], do: nil
  defp blank_to_nil_value(value), do: value

  def create_exception(conn, %{"exception" => params}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, starts_at} <- parse_datetime(params["starts_at"]),
         {:ok, ends_at} <- parse_datetime(params["ends_at"]) do
      attrs = %{
        doctor_id: doctor.id,
        starts_at: starts_at,
        ends_at: ends_at,
        reason: params["reason"] || "doctor_day_off",
        status: "blocked",
        source: "manual"
      }

      # Create both for now to maintain consistency
      Scheduling.create_schedule_exception(Map.put(attrs, :exception_type, "blocked"))
      Scheduling.create_availability_exception(attrs)

      conn
      |> put_flash(:success, dgettext("default", "Time off added"))
      |> redirect(to: ~p"/doctor/schedule")
    else
      _ ->
        conn
        |> put_flash(:error, dgettext("default", "Unable to add time off"))
        |> redirect(to: ~p"/doctor/schedule")
    end
  end

  def delete_exception(conn, %{"id" => id}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, exception} <- Scheduling.get_availability_exception(id),
         true <- exception.doctor_id == doctor.id,
         :ok <- Scheduling.delete_availability_exception(exception) do
      conn
      |> put_flash(:success, dgettext("default", "Time off removed"))
      |> redirect(to: ~p"/doctor/schedule")
    else
      _ ->
        conn
        |> put_flash(:error, dgettext("default", "Unable to remove time off"))
        |> redirect(to: ~p"/doctor/schedule")
    end
  end

  defp fetch_doctor(user) do
    case Doctors.get_doctor_by_user_id(user.id) do
      nil -> {:error, :not_found}
      doctor -> {:ok, doctor}
    end
  end

  defp fetch_rule(id, doctor_id) do
    rule = Scheduling.get_availability_rule!(id)

    if rule.doctor_id == doctor_id do
      {:ok, rule}
    else
      {:error, :forbidden}
    end
  rescue
    _ -> {:error, :not_found}
  end

  defp rule_props(rule) do
    %{
      id: Map.get(rule, :id),
      dayOfWeek: Map.get(rule, :day_of_week),
      startTime: format_time(Map.get(rule, :start_time)),
      endTime: format_time(Map.get(rule, :end_time)),
      breakStart: format_time(Map.get(rule, :break_start)),
      breakEnd: format_time(Map.get(rule, :break_end)),
      breaks:
        Enum.map(Map.get(rule, :breaks, []), fn b ->
          %{
            breakStartLocal: format_time(b.break_start_local),
            breakEndLocal: format_time(b.break_end_local)
          }
        end),
      slotDurationMinutes: Map.get(rule, :slot_duration_minutes, 30),
      isActive: Map.get(rule, :is_active, true),
      visitType: Map.get(rule, :visit_type)
    }
  end

  defp format_time(nil), do: nil
  defp format_time(%Time{} = time), do: Calendar.strftime(time, "%H:%M")
  defp format_time(%NaiveDateTime{} = dt), do: dt |> NaiveDateTime.to_time() |> format_time()
  defp format_time(value) when is_binary(value), do: value
  defp format_time(_), do: nil

  defp appointment_props(appt) do
    %{
      id: appt.id,
      starts_at: DateTime.to_iso8601(appt.starts_at),
      status: appt.status,
      patient: %{
        first_name: appt.patient && appt.patient.first_name,
        last_name: appt.patient && appt.patient.last_name
      }
    }
  end

  # POST /api/doctor/schedule/preview
  def preview(conn, params) do
    # Ensure we fetch the doctor associated with the current user
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user) do
      result = Scheduling.preview_slots(doctor.id, params)
      json(conn, result)
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Doctor not found"})
    end
  end

  # POST /api/doctor/schedule/rules/bulk_upsert
  def bulk_upsert(conn, params) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user) do
      result = Scheduling.bulk_upsert_schedule_rules!(doctor.id, params)
      json(conn, %{ok: true, result: result})
    else
      _ ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Doctor not found"})
    end
  rescue
    e ->
      # In production, map Ash errors into {path, code, message} and return 422
      conn
      |> put_status(:unprocessable_entity)
      |> json(%{ok: false, error: Exception.message(e)})
  end

  defp parse_datetime(nil), do: {:error, :missing_date}

  defp parse_datetime(iso_str) do
    case DateTime.from_iso8601(iso_str) do
      {:ok, dt, _offset} -> {:ok, dt}
      _ -> {:error, :invalid_format}
    end
  end

  defp exception_props(ex) do
    %{
      id: ex.id,
      starts_at: DateTime.to_iso8601(ex.starts_at),
      ends_at: DateTime.to_iso8601(ex.ends_at),
      reason: ex.reason
    }
  end
end
