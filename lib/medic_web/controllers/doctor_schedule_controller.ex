defmodule MedicWeb.DoctorScheduleController do
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Doctors
  alias Medic.Scheduling

  def show(conn, _params) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user) do
      rules = Scheduling.list_schedule_rules_for_ui(doctor.id)

      upcoming =
        Appointments.list_appointments(
          doctor_id: doctor.id,
          upcoming: true,
          preload: [:patient]
        )

      conn
      |> assign(:page_title, dgettext("default", "Schedule"))
      |> assign_prop(:availability_rules, Enum.map(rules, &rule_props/1))
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

  def block_day(conn, %{"exception" => %{"date" => date}}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, parsed_date} <- Date.from_iso8601(date),
         {:ok, starts_at} <- DateTime.new(parsed_date, ~T[00:00:00], "Etc/UTC"),
         {:ok, ends_at} <- DateTime.new(parsed_date, ~T[23:59:59], "Etc/UTC"),
         {:ok, _} <-
           Scheduling.create_schedule_exception(%{
             doctor_id: doctor.id,
             starts_at: starts_at,
             ends_at: ends_at,
             exception_type: "blocked",
             reason: "doctor_day_off",
             source: "manual"
           }),
         {:ok, _} <-
           Scheduling.create_availability_exception(%{
             doctor_id: doctor.id,
             starts_at: starts_at,
             ends_at: ends_at,
             status: "blocked",
             reason: "doctor_day_off",
             source: "manual"
           }) do
      conn
      |> put_flash(:success, dgettext("default", "Day blocked"))
      |> redirect(to: ~p"/doctor/schedule")
    else
      _ ->
        conn
        |> put_flash(:error, dgettext("default", "Unable to block day"))
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
      day_of_week: Map.get(rule, :day_of_week),
      start_time: format_time(Map.get(rule, :start_time)),
      end_time: format_time(Map.get(rule, :end_time)),
      break_start: format_time(Map.get(rule, :break_start)),
      break_end: format_time(Map.get(rule, :break_end)),
      slot_duration_minutes: Map.get(rule, :slot_duration_minutes, 30),
      is_active: Map.get(rule, :is_active, true)
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
end
