defmodule MedicWeb.AppreciationController do
  use MedicWeb, :controller

  alias Medic.Appreciate.Service
  alias Medic.Patients

  def create(conn, params) do
    appointment_id = Map.get(params, "id") || Map.get(params, "appointment_id")

    if is_nil(appointment_id) do
      if ajax?(conn) do
        send_resp(conn, :unprocessable_entity, "")
      else
        conn
        |> put_flash(:error, "Unable to submit appreciation.")
        |> redirect(to: ~p"/dashboard")
      end
    else
      with %{id: user_id} <- conn.assigns.current_user,
           patient when not is_nil(patient) <- Patients.get_patient_by_user_id(user_id),
           {:ok, _appreciation} <-
             Service.appreciate_appointment(%{
               appointment_id: appointment_id,
               patient_id: patient.id,
               note_text: Map.get(params, "note_text")
             }) do
        if ajax?(conn) do
          send_resp(conn, :no_content, "")
        else
          conn
          |> put_flash(:success, "Thank you. Your appreciation helps others find great care.")
          |> redirect(to: ~p"/appointments/#{appointment_id}")
        end
      else
        nil ->
          if ajax?(conn) do
            send_resp(conn, :unprocessable_entity, "")
          else
            conn
            |> put_flash(:error, "Please create a patient profile first.")
            |> redirect(to: ~p"/appointments/#{appointment_id}")
          end

        {:error, error} ->
          status =
            if already_appreciated_error?(error), do: :conflict, else: :unprocessable_entity

          body = if status == :conflict, do: "already_appreciated", else: "unable_to_submit"

          if ajax?(conn) do
            send_resp(conn, status, body)
          else
            message =
              if status == :conflict do
                "You already appreciated this appointment."
              else
                "Unable to submit appreciation."
              end

            conn
            |> put_flash(:error, message)
            |> redirect(to: ~p"/appointments/#{appointment_id}")
          end
      end
    end
  end

  defp already_appreciated_error?(error) do
    error_text = Exception.format(:error, error, [])

    String.contains?(error_text, "doctor_appreciations_appointment_id_index") or
      String.contains?(error_text, "unique_appointment")
  rescue
    _ -> false
  end

  defp ajax?(conn) do
    inertia? = get_req_header(conn, "x-inertia") != []

    Enum.any?(get_req_header(conn, "x-requested-with"), fn h ->
      String.downcase(h) == "xmlhttprequest"
    end) or inertia?
  end
end
