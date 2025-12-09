defmodule MedicWeb.Router do
  use MedicWeb, :router

  import MedicWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MedicWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug MedicWeb.Plugs.Locale
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes
  scope "/", MedicWeb do
    pipe_through :browser

    live_session :public,
      layout: {MedicWeb.Layouts, :app},
      on_mount: [{MedicWeb.UserAuth, :mount_current_user}, {MedicWeb.LiveHooks.Locale, :default}] do
      live "/", HomeLive
      live "/search", SearchLive
      live "/doctors/:id", DoctorLive.Show
    end
  end

  # Routes that require user to NOT be logged in
  scope "/", MedicWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      layout: {MedicWeb.Layouts, :app},
      on_mount: [{MedicWeb.UserAuth, :redirect_if_user_is_authenticated}, {MedicWeb.LiveHooks.Locale, :default}] do
      live "/login", UserLoginLive
      live "/register", UserRegistrationLive
      live "/register/doctor", UserRegistrationLive, :doctor
    end

    post "/login", UserSessionController, :create
  end

  # Authenticated routes for all users
  scope "/", MedicWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      layout: {MedicWeb.Layouts, :app},
      on_mount: [{MedicWeb.UserAuth, :ensure_authenticated}, {MedicWeb.LiveHooks.Locale, :default}] do
      live "/dashboard", DashboardLive
      live "/appointments/:id", AppointmentLive.Show
      live "/settings", SettingsLive
      live "/onboarding/doctor", DoctorOnboardingLive
      live "/doctor/schedule", DoctorLive.Schedule
    end

    delete "/logout", UserSessionController, :delete
  end

  # Doctor-specific routes
  scope "/dashboard", MedicWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :doctor_dashboard,
      layout: {MedicWeb.Layouts, :app},
      on_mount: [{MedicWeb.UserAuth, :ensure_authenticated}, {MedicWeb.LiveHooks.Locale, :default}] do
      live "/doctor", DoctorDashboardLive
      live "/doctor/profile", DoctorLive.Profile
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:medic, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MedicWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
