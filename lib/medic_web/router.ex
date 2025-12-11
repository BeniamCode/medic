defmodule MedicWeb.Router do
  use MedicWeb, :router

  import MedicWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug Inertia.Plug
    plug :fetch_live_flash
    plug :put_root_layout, html: {MedicWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
    plug MedicWeb.Plugs.Locale
    plug MedicWeb.Plugs.InertiaContext
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :admin_layout do
    plug :put_layout, html: {MedicWeb.Layouts, :admin}
  end

  # Public routes
  scope "/", MedicWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/search", SearchController, :index
    get "/doctors/:id", DoctorController, :show
  end

  # Routes that require user to NOT be logged in
  scope "/", MedicWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/login", UserSessionController, :new
    post "/login", UserSessionController, :create
    get "/register", UserRegistrationController, :new
    post "/register", UserRegistrationController, :create

    # Doctor Registration
    get "/register/doctor", UserRegistrationController, :new_doctor
    post "/register/doctor", UserRegistrationController, :create_doctor
  end

  # Authenticated routes for all users
  scope "/", MedicWeb do
    pipe_through [:browser, :require_authenticated_user, MedicWeb.Plugs.RequireDoctorOnboarding]

    live_session :require_authenticated_user,
      layout: {MedicWeb.Layouts, :app},
      on_mount: [
        {MedicWeb.UserAuth, :ensure_authenticated},
        {MedicWeb.LiveHooks.Locale, :default}
      ] do
      get "/dashboard", DashboardController, :show
      get "/appointments/:id", AppointmentsController, :show
      get "/settings", SettingsController, :show
      get "/onboarding/doctor", DoctorOnboardingController, :show
      post "/onboarding/doctor", DoctorOnboardingController, :update
      get "/doctor/schedule", DoctorScheduleController, :show
      post "/doctor/schedule", DoctorScheduleController, :update
      delete "/doctor/schedule/:id", DoctorScheduleController, :delete
      post "/notifications/mark_all", NotificationController, :mark_all
      get "/notifications", NotificationController, :index
    end

    post "/doctors/:id/book", DoctorController, :book
    delete "/logout", UserSessionController, :delete
  end

  # Doctor-specific routes
  scope "/dashboard", MedicWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/doctor", DoctorDashboardController, :show
    get "/doctor/profile", DoctorProfileController, :show
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

  # --- Admin Routes ---
  scope "/medic", MedicWeb do
    pipe_through [:browser, :admin_layout]

    # Admin Login (Unauthenticated)
    live_session :admin_login,
      on_mount: [{MedicWeb.UserAuth, :mount_current_user}, {MedicWeb.LiveHooks.Locale, :default}] do
      live "/login", AdminLoginLive
    end

    # Authenticated Admin Routes
    live_session :admin_dashboard,
      on_mount: [{MedicWeb.UserAuth, :ensure_admin_user}, {MedicWeb.LiveHooks.Locale, :default}] do
      # Dashboard
      live "/dashboard", Admin.DashboardLive

      # CMS
      live "/doctors", Admin.DoctorLive.Index, :index
      live "/doctors/:id/edit", Admin.DoctorLive.Index, :edit

      live "/patients", Admin.PatientLive.Index, :index
      live "/patients/:id/edit", Admin.PatientLive.Index, :edit

      live "/on_duty", Admin.OnDutyLive

      live "/reviews", Admin.ReviewLive.Index, :index
      live "/financials", Admin.FinancialLive, :index
    end
  end
end
