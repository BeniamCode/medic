defmodule Medic.AppointmentsNotificationsTest do
  use Medic.DataCase

  alias Medic.Appointments
  alias Medic.Doctors
  alias Medic.Notifications
  alias Medic.Patients

  defp future_window() do
    starts_at = DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(86_400, :second)
    ends_at = DateTime.add(starts_at, 30 * 60, :second)
    {starts_at, ends_at}
  end

  defp create_doctor_and_patient!() do
    {:ok, doctor_user} =
      Medic.Accounts.register_user(%{
        email: "doctor_#{System.unique_integer()}@example.com",
        password: "Password123!",
        role: "doctor"
      })

    {:ok, patient_user} =
      Medic.Accounts.register_user(%{
        email: "patient_#{System.unique_integer()}@example.com",
        password: "Password123!",
        role: "patient"
      })

    doctor =
      Doctors.get_doctor_by_user_id(doctor_user.id) ||
        case Doctors.create_doctor(doctor_user, %{
               first_name: "Dana",
               last_name: "Scully",
               title: "Dr",
               city: "Athens"
             }) do
          {:ok, doctor} -> doctor
          {:error, reason} -> raise "Unable to create doctor: #{inspect(reason)}"
        end

    patient =
      Patients.get_patient_by_user_id(patient_user.id) ||
        case Patients.create_patient(patient_user, %{
               first_name: "Fox",
               last_name: "Mulder"
             }) do
          {:ok, patient} -> patient
          {:error, reason} -> raise "Unable to create patient: #{inspect(reason)}"
        end

    %{doctor: doctor, doctor_user: doctor_user, patient: patient, patient_user: patient_user}
  end

  test "create_appointment notifies doctor and patient" do
    %{doctor: doctor, doctor_user: doctor_user, patient: patient, patient_user: patient_user} =
      create_doctor_and_patient!()

    {starts_at, ends_at} = future_window()

    assert {:ok, appointment} =
             Appointments.create_appointment(%{
               doctor_id: doctor.id,
               patient_id: patient.id,
               starts_at: starts_at,
               ends_at: ends_at,
               consultation_mode_snapshot: "in_person"
             })

    doctor_notifications = Notifications.list_user_notifications(doctor_user.id, 10)
    patient_notifications = Notifications.list_user_notifications(patient_user.id, 10)

    assert Enum.any?(doctor_notifications, &(&1.resource_id == appointment.id))
    assert Enum.any?(patient_notifications, &(&1.resource_id == appointment.id))

    assert Enum.any?(doctor_notifications, &(&1.title == "New Appointment Request"))
    assert Enum.any?(patient_notifications, &(&1.title == "Appointment requested"))
  end

  test "reject_request notifies patient" do
    %{doctor: doctor, doctor_user: doctor_user, patient: patient, patient_user: patient_user} =
      create_doctor_and_patient!()

    {starts_at, ends_at} = future_window()

    assert {:ok, appointment} =
             Appointments.create_appointment(%{
               doctor_id: doctor.id,
               patient_id: patient.id,
               starts_at: starts_at,
               ends_at: ends_at,
               consultation_mode_snapshot: "in_person"
             })

    assert {:ok, updated} =
             Appointments.reject_request(appointment, "No availability", %{
               actor_type: :doctor,
               actor_id: doctor.id
             })

    assert updated.status == "cancelled"

    patient_notifications = Notifications.list_user_notifications(patient_user.id, 20)
    assert Enum.any?(patient_notifications, &(&1.resource_id == appointment.id))
    assert Enum.any?(patient_notifications, &String.contains?(&1.message, "declined"))

    # Doctor may or may not receive a cancellation notice depending on flows; ensure no crash.
    _doctor_notifications = Notifications.list_user_notifications(doctor_user.id, 20)
  end
end
