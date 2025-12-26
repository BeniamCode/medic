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

  pipeline :admin_auth do
    plug MedicWeb.Plugs.RequireAdminUser
  end

  # SSE (Server-Sent Events) pipeline for notification streaming
  pipeline :sse do
    plug :accepts, ["html", "sse"]
    plug :fetch_session
    plug :fetch_current_user
  end


  # Public routes
  scope "/", MedicWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/search", SearchController, :index
    get "/doctors/:id", DoctorController, :show
    get "/users/confirm/:token", UserConfirmationController, :update
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
      post "/appointments/:id/appreciate", AppreciationController, :create
      post "/appointments/:id/approve_reschedule", AppointmentsController, :approve_reschedule
      post "/appointments/:id/experience_submission", ExperienceSubmissionController, :create
      post "/appointments/:id/reject_reschedule", AppointmentsController, :reject_reschedule
      post "/appointments/:id/cancel", AppointmentsController, :cancel
      get "/settings", SettingsController, :show
      get "/onboarding/doctor", DoctorOnboardingController, :show
      post "/onboarding/doctor", DoctorOnboardingController, :update
      get "/doctor/schedule", DoctorScheduleController, :show
      post "/doctor/schedule", DoctorScheduleController, :update
      delete "/doctor/schedule/:id", DoctorScheduleController, :delete
      post "/doctor/schedule/day_off", DoctorScheduleController, :block_day
      get "/notifications/recent_unread", NotificationController, :recent_unread
      post "/notifications/mark_all", NotificationController, :mark_all
      post "/notifications/:id/read", NotificationController, :mark_read
      get "/notifications", NotificationController, :index
    end

    post "/doctors/:id/book", DoctorController, :book
    delete "/logout", UserSessionController, :delete

    scope "/api/doctor/schedule" do
      post "/preview", DoctorScheduleController, :preview
      post "/rules/bulk_upsert", DoctorScheduleController, :bulk_upsert
    end

    post "/doctor/schedule/exceptions", DoctorScheduleController, :create_exception
    delete "/doctor/schedule/exceptions/:id", DoctorScheduleController, :delete_exception
  end

  # SSE notification stream - separate from browser pipeline to accept event-stream
  scope "/", MedicWeb do
    pipe_through [:sse, :require_authenticated_user]

    get "/notifications/stream", NotificationStreamController, :stream
  end

  # Doctor-specific routes
  scope "/dashboard", MedicWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/doctor", DoctorDashboardController, :show
    get "/doctor/appointments", DoctorAppointmentsController, :index
    post "/doctor/appointments/:id/approve", DoctorAppointmentsController, :approve
    post "/doctor/appointments/:id/reject", DoctorAppointmentsController, :reject
    post "/doctor/appointments/:id/reschedule", DoctorAppointmentsController, :reschedule
    post "/doctor/appointments/:id/cancel", DoctorAppointmentsController, :cancel
    get "/doctor/profile", DoctorProfileController, :show
    post "/doctor/profile", DoctorProfileController, :update
    post "/doctor/profile/image", DoctorProfileController, :upload_image

    # Booking Calendar
    get "/doctor/calendar", Doctor.BookingCalendarController, :index
    post "/doctor/calendar/month-data", Doctor.BookingCalendarController, :month_data
    post "/doctor/calendar/day-slots", Doctor.BookingCalendarController, :day_slots
    post "/doctor/calendar/search-patient", Doctor.BookingCalendarController, :search_patient
    post "/doctor/calendar/create-booking", Doctor.BookingCalendarController, :create_booking

    get "/patient/profile", PatientProfileController, :show
    post "/patient/profile", PatientProfileController, :update
    post "/patient/profile/image", PatientProfileController, :upload_image
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

  pipeline :api_public do
    plug :accepts, ["json"]
  end

  pipeline :api_authenticated do
    plug :accepts, ["json"]
    plug MedicWeb.Plugs.VerifyApiToken
  end

  # --- Public API Routes ---
  scope "/api", MedicWeb.API do
    pipe_through :api_public

    # Auth
    post "/auth/login", AuthController, :login
    post "/auth/register", AuthController, :register
    post "/auth/forgot_password", AuthController, :forgot_password
    post "/auth/reset_password", AuthController, :reset_password

    # Doctors (public)
    get "/doctors", DoctorController, :index
    get "/doctors/:id", DoctorController, :show
    get "/doctors/:id/availability", DoctorController, :availability
    get "/doctors/:id/appointment_types", DoctorController, :appointment_types
    get "/doctors/:doctor_id/reviews", ReviewController, :index

    # Specialties (public)
    get "/specialties", SpecialtyController, :index
  end

  # --- Authenticated API Routes ---
  scope "/api", MedicWeb.API do
    pipe_through :api_authenticated

    # Auth
    get "/auth/me", AuthController, :me
    post "/auth/refresh", AuthController, :refresh
    post "/auth/change_password", AuthController, :change_password

    # Appointments
    get "/appointments", AppointmentController, :index
    get "/appointments/:id", AppointmentController, :show
    post "/appointments", AppointmentController, :create
    post "/appointments/:id/cancel", AppointmentController, :cancel
    post "/appointments/:id/approve", AppointmentController, :approve
    post "/appointments/:id/reject", AppointmentController, :reject
    post "/appointments/:id/appreciate", AppointmentController, :appreciate
    post "/appointments/:id/experience", AppointmentController, :experience
    post "/appointments/:id/reschedule", AppointmentController, :reschedule
    post "/appointments/:id/approve_reschedule", AppointmentController, :approve_reschedule
    post "/appointments/:id/reject_reschedule", AppointmentController, :reject_reschedule

    # Profile
    get "/profile", ProfileController, :show
    put "/profile", ProfileController, :update

    # Notifications
    get "/notifications", NotificationController, :index
    post "/notifications/:id/read", NotificationController, :mark_read
    post "/notifications/mark_all", NotificationController, :mark_all

    # Doctor Portal
    get "/doctor/dashboard", DoctorPortalController, :dashboard
    get "/doctor/patients", DoctorPortalController, :patients
    get "/doctor/schedule", DoctorPortalController, :schedule
    put "/doctor/schedule", DoctorPortalController, :update_schedule
    post "/doctor/schedule/exceptions", DoctorPortalController, :create_exception
    delete "/doctor/schedule/exceptions/:id", DoctorPortalController, :delete_exception

    # Patient Portal
    get "/patient/dashboard", PatientPortalController, :dashboard
    get "/patient/doctors", PatientPortalController, :doctors

    # Reviews (authenticated to post)
    post "/doctors/:doctor_id/reviews", ReviewController, :create

    # Push Notifications
    post "/devices", DeviceController, :create
    delete "/devices/:token", DeviceController, :delete
  end

  # --- Admin Routes ---
  scope "/medic", MedicWeb.Admin do
    pipe_through :browser

    # Admin Login (unauthenticated)
    get "/login", AuthController, :new
    post "/login", AuthController, :create
  end

  scope "/medic", MedicWeb.Admin do
    pipe_through [:browser, :admin_auth]

    # Admin logout
    delete "/logout", AuthController, :delete

    # Dashboard
    get "/dashboard", DashboardController, :index

    # User Management
    get "/users", UsersController, :index
    delete "/users/:id", UsersController, :delete

    # Appointment Management
    get "/appointments", AppointmentsController, :index
    post "/appointments/:id/cancel", AppointmentsController, :cancel

    # Keep existing routes (will convert later)
    get "/doctors", DoctorsController, :index
    get "/patients", PatientsController, :index
    get "/reviews", ReviewsController, :index
    get "/financials", FinancialsController, :index

    # Email Management
    get "/email_templates", EmailTemplatesController, :index
    get "/email_templates/new", EmailTemplatesController, :new
    post "/email_templates", EmailTemplatesController, :create
    get "/email_templates/:id/edit", EmailTemplatesController, :edit
    put "/email_templates/:id", EmailTemplatesController, :update
    delete "/email_templates/:id", EmailTemplatesController, :delete

    get "/email_logs", EmailLogsController, :index
  post "/email_logs/:id/resend", EmailLogsController, :resend
  post "/email_debug/send", EmailDebugController, :send_test_email
  end
end
