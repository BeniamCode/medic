defmodule MedicWeb.Plugs.RequireDoctorOnboarding do
  @moduledoc """
  Redirects doctor users to the onboarding wizard if their profile is incomplete.
  Completion is determined by the presence of a 'consultation_fee' (set in the final step).
  """
  import Plug.Conn
  import Phoenix.Controller
  use MedicWeb, :verified_routes

  alias Medic.Doctors

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    if user && user.role == "doctor" do
      check_onboarding(conn, user)
    else
      conn
    end
  end

  defp check_onboarding(conn, user) do
    # Allow onboarding routes and logout to pass through
    if onboarding_route?(conn.request_path) do
      conn
    else
      doctor = Doctors.get_doctor_by_user_id(user.id)

      if is_nil(doctor) || is_nil(doctor.consultation_fee) do
        conn
        |> put_flash(:info, "Please complete your profile configuration.")
        |> redirect(to: ~p"/onboarding/doctor")
        |> halt()
      else
        conn
      end
    end
  end

  defp onboarding_route?(path) do
    # Allowing onboarding routes, logout, and static assets/api if needed.
    # Assuming standard paths.
    
    String.starts_with?(path, "/onboarding/doctor") || 
      path == "/logout" || 
      String.starts_with?(path, "/assets")
  end
end
