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

        {:error, _} ->
          if ajax?(conn) do
            send_resp(conn, :unprocessable_entity, "")
          else
            conn
            |> put_flash(:error, "Unable to submit appreciation.")
            |> redirect(to: ~p"/appointments/#{appointment_id}")
          end
      end
    end
  end

  defp ajax?(conn) do
    inertia? = get_req_header(conn, "x-inertia") != []

    Enum.any?(get_req_header(conn, "x-requested-with"), fn h ->
      String.downcase(h) == "xmlhttprequest"
    end) or inertia?
  end
end
