defmodule MedicWeb.DoctorScheduleController do
  use MedicWeb, :controller

  alias Medic.Appointments
  alias Medic.Doctors
  alias Medic.Scheduling
  alias Medic.Scheduling.AvailabilityRule

  def show(conn, _params) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user) do
      rules = Scheduling.list_availability_rules(doctor.id, include_inactive: true)

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
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user) do
      attrs =
        rule_params
        |> normalize_rule_params()
        |> Map.put("doctor_id", doctor.id)

      result =
        case Map.get(attrs, "id") do
          "" ->
            Scheduling.create_availability_rule(attrs)

          nil ->
            Scheduling.create_availability_rule(attrs)

          id ->
            rule = Scheduling.get_availability_rule!(id)
            Scheduling.update_availability_rule(rule, attrs)
        end

      case result do
        {:ok, _rule} ->
          conn
          |> put_flash(:success, dgettext("default", "Availability saved"))
          |> redirect(to: ~p"/doctor/schedule")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, dgettext("default", "Unable to save rule"))
          |> redirect(to: ~p"/doctor/schedule")
      end
    else
      _ -> redirect(conn, to: ~p"/doctor/schedule")
    end
  end

  def delete(conn, %{"id" => id}) do
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
    params
    |> Map.update("day_of_week", nil, fn
      value when is_binary(value) and value != "" -> String.to_integer(value)
      value -> value
    end)
    |> Map.update("slot_duration_minutes", nil, fn
      value when is_binary(value) and value != "" -> String.to_integer(value)
      value when is_float(value) -> round(value)
      value -> value
    end)
    |> Map.update("break_start", nil, blank_to_nil())
    |> Map.update("break_end", nil, blank_to_nil())
    |> Map.update("id", nil, fn
      "" -> nil
      value -> value
    end)
    |> Map.update("is_active", true, fn
      value when value in ["false", false] -> false
      _ -> true
    end)
  end

  defp blank_to_nil do
    fn
      value when value in [nil, ""] -> nil
      value -> value
    end
  end

  def block_day(conn, %{"exception" => %{"date" => date}}) do
    with {:ok, doctor} <- fetch_doctor(conn.assigns.current_user),
         {:ok, parsed_date} <- Date.from_iso8601(date),
         {:ok, starts_at} <- DateTime.new(parsed_date, ~T[00:00:00], "Etc/UTC"),
         {:ok, ends_at} <- DateTime.new(parsed_date, ~T[23:59:59], "Etc/UTC"),
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

  defp rule_props(%AvailabilityRule{} = rule) do
    %{
      id: rule.id,
      day_of_week: rule.day_of_week,
      start_time: Calendar.strftime(rule.start_time, "%H:%M"),
      end_time: Calendar.strftime(rule.end_time, "%H:%M"),
      break_start: rule.break_start && Calendar.strftime(rule.break_start, "%H:%M"),
      break_end: rule.break_end && Calendar.strftime(rule.break_end, "%H:%M"),
      slot_duration_minutes: rule.slot_duration_minutes,
      is_active: rule.is_active
    }
  end

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
end
