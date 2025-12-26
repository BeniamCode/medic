defmodule MedicWeb.Doctor.BookingCalendarControllerTest do
  use MedicWeb.ConnCase

  setup do
    # Create valid specialty
    specialty = Medic.Doctors.Specialty
                |> Ash.Changeset.for_create(:create, %{name_en: "General Practice", name_el: "Γενική Ιατρική", slug: "general"})
                |> Ash.create!()

    # Create a user and doctor for testing
    user = Medic.Accounts.User
           |> Ash.Changeset.for_create(:create, %{
                email: "doctor@example.com",
                hashed_password: "hashed_password_123",
                role: "doctor"
              })
           |> Ash.create!()

    # Create doctor profile
    doctor = Medic.Doctors.Doctor
             |> Ash.Changeset.for_create(:create, %{
                first_name: "John",
                last_name: "Doe",
                user_id: user.id,
                specialty_id: specialty.id
              })
             |> Ash.create!()

    # Create an UNCLAIMED patient with email
    unclaimed = Medic.Patients.Patient
               |> Ash.Changeset.for_create(:create, %{
                 first_name: "Unclaimed",
                 last_name: "Patient",
                 email: "unclaimed@example.com"
               })
               |> Ash.Changeset.force_change_attribute(:doctor_initiated, true)
               |> Ash.create!()

    {:ok, user: user, doctor: doctor, unclaimed: unclaimed}
  end

  test "search_patient finds unclaimed patient by email", %{conn: conn, user: user, unclaimed: unclaimed} do
    token = Medic.Accounts.generate_user_session_token(user)
    conn = conn
           |> init_test_session(%{user_token: token})
           |> post(~p"/dashboard/doctor/calendar/search-patient", %{
             "email" => "unclaimed@example.com"
           })
    
    assert json_response(conn, 200)
    assert %{"patients" => [found]} = json_response(conn, 200)
    assert found["id"] == unclaimed.id
    assert found["email"] == "unclaimed@example.com"
  end

  test "create_booking creates appointment and returns success", %{conn: conn, user: user} do
    token = Medic.Accounts.generate_user_session_token(user)
    
    # Needs valid dates
    starts_at = DateTime.utc_now() |> DateTime.add(24, :hour) |> DateTime.to_iso8601()
    ends_at = DateTime.utc_now() |> DateTime.add(25, :hour) |> DateTime.to_iso8601()

    conn = conn
           |> init_test_session(%{user_token: token})
           |> post(~p"/dashboard/doctor/calendar/create-booking", %{
             "starts_at" => starts_at,
             "ends_at" => ends_at,
             "patient" => %{
               "first_name" => "New",
               "last_name" => "Booking",
               "email" => "newbooking@example.com",
               "phone" => "6900000000"
             }
           })

    assert json_response(conn, 200)
    resp = json_response(conn, 200)
    assert resp["success"] == true
    assert resp["appointment"]["patient"]["first_name"] == "New"
  end
end
