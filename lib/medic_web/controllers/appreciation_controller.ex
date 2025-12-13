defmodule MedicWeb.AppreciationController do
  use MedicWeb, :controller

  alias Medic.Appreciate.Service
  alias Medic.Patients

  def create(conn, %{"appointment_id" => appointment_id} = params) do
    appointment_id = Map.get(params, "id") || appointment_id

    with %{id: user_id} <- conn.assigns.current_user,
         patient when not is_nil(patient) <- Patients.get_patient_by_user_id(user_id),
         {:ok, _appreciation} <-
           Service.appreciate_appointment(%{
             appointment_id: appointment_id,
             patient_id: patient.id,
             note_text: Map.get(params, "note_text")
           }) do
      conn
      |> put_flash(:success, "Thank you. Your appreciation helps others find great care.")
      |> redirect(to: ~p"/appointments/#{appointment_id}")
    else
      nil ->
        conn
        |> put_flash(:error, "Please create a patient profile first.")
        |> redirect(to: ~p"/appointments/#{appointment_id}")

      {:error, _} ->
        conn
        |> put_flash(:error, "Unable to submit appreciation.")
        |> redirect(to: ~p"/appointments/#{appointment_id}")
    end
  end
end
