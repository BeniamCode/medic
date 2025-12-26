defmodule Medic.Emails do
  @moduledoc """
  Email composition module for medical appointment notifications.

  Uses Swoosh to build emails, fetching templates from the database via Medic.Notifications.EmailTemplate.
  Falls back to hardcoded templates if database templates are missing.
  """

  import Swoosh.Email

  alias Medic.Emails.Config
  alias Medic.Notifications
  alias Medic.Notifications.TemplateRenderer

  # Default sender for appointment-related emails
  defp from_address, do: Config.sender(:appointments)

  @doc """
  Builds a confirmation email for the patient when an appointment is confirmed.
  """
  def appointment_confirmation(appointment) do
    patient = appointment.patient
    doctor = appointment.doctor
    user = patient.user

    starts_at_formatted = format_datetime(appointment.starts_at, appointment.patient_timezone)
    doctor_name = "Dr. #{doctor.first_name} #{doctor.last_name}"

    variables = %{
      "patient_name" => patient.first_name,
      "doctor_name" => doctor_name,
      "starts_at" => starts_at_formatted,
      "duration_minutes" => appointment.duration_minutes || 30,
      "consultation_mode" => humanize_mode(appointment.consultation_mode_snapshot)
    }

    render_email(
      "appointment_confirmation",
      variables,
      {patient.first_name, user.email},
      fn ->
        # Fallback content
        new()
        |> to({patient.first_name, user.email})
        |> from(from_address())
        |> subject("Your appointment with #{doctor_name} is confirmed")
        |> text_body("""
        Hello #{patient.first_name},

        Your appointment has been confirmed!

        Details:
        - Doctor: #{doctor_name}
        - Date & Time: #{starts_at_formatted}
        - Duration: #{appointment.duration_minutes || 30} minutes
        - Type: #{humanize_mode(appointment.consultation_mode_snapshot)}

        If you need to reschedule or cancel, please do so at least 24 hours before your appointment.

        Thank you for choosing Medic!

        Best regards,
        The Medic Team
        """)
      end
    )
  end

  @doc """
  Builds an email alert for the doctor when they receive a new booking.
  """
  def new_booking_for_doctor(appointment) do
    patient = appointment.patient
    doctor = appointment.doctor
    doctor_user = doctor.user

    starts_at_formatted = format_datetime(appointment.starts_at, appointment.doctor_timezone)
    patient_name = "#{patient.first_name} #{patient.last_name}"

    variables = %{
      "doctor_name" => doctor.last_name,
      "patient_name" => patient_name,
      "starts_at" => starts_at_formatted,
      "duration_minutes" => appointment.duration_minutes || 30,
      "consultation_mode" => humanize_mode(appointment.consultation_mode_snapshot),
      "notes" => appointment.notes || ""
    }

    render_email(
      "new_booking_for_doctor",
      variables,
      {doctor.first_name, doctor_user.email},
      fn ->
        new()
        |> to({doctor.first_name, doctor_user.email})
        |> from(from_address())
        |> subject("New appointment booked: #{patient_name}")
        |> text_body("""
        Hello Dr. #{doctor.last_name},

        You have a new appointment booking!

        Patient: #{patient_name}
        Date & Time: #{starts_at_formatted}
        Duration: #{appointment.duration_minutes || 30} minutes
        Type: #{humanize_mode(appointment.consultation_mode_snapshot)}
        #{if appointment.notes, do: "Notes: #{appointment.notes}", else: ""}

        Please review your schedule and prepare accordingly.

        Best regards,
        The Medic Team
        """)
      end
    )
  end

  @doc """
  Builds a cancellation email for the patient when an appointment is cancelled.
  """
  def appointment_cancelled_patient(appointment) do
    patient = appointment.patient
    doctor = appointment.doctor
    user = patient.user

    starts_at_formatted = format_datetime(appointment.starts_at, appointment.patient_timezone)
    doctor_name = "Dr. #{doctor.first_name} #{doctor.last_name}"
    cancellation_reason = appointment.cancellation_reason || ""

    variables = %{
      "patient_name" => patient.first_name,
      "doctor_name" => doctor_name,
      "starts_at" => starts_at_formatted,
      "cancellation_reason" => cancellation_reason
    }

    render_email(
      "appointment_cancelled_patient",
      variables,
      {patient.first_name, user.email},
      fn ->
        reason_text = if cancellation_reason != "", do: "\nReason: #{cancellation_reason}", else: ""
        
        new()
        |> to({patient.first_name, user.email})
        |> from(from_address())
        |> subject("Appointment cancelled: #{doctor_name}")
        |> text_body("""
        Hello #{patient.first_name},

        Your appointment has been cancelled.

        Original appointment details:
        - Doctor: #{doctor_name}
        - Date & Time: #{starts_at_formatted}#{reason_text}

        If you'd like to reschedule, please visit our website or mobile app.

        We apologize for any inconvenience.

        Best regards,
        The Medic Team
        """)
      end
    )
  end

  @doc """
  Builds a cancellation email for the doctor when an appointment is cancelled.
  """
  def appointment_cancelled_doctor(appointment) do
    patient = appointment.patient
    doctor = appointment.doctor
    doctor_user = doctor.user

    starts_at_formatted = format_datetime(appointment.starts_at, appointment.doctor_timezone)
    patient_name = "#{patient.first_name} #{patient.last_name}"
    cancellation_reason = appointment.cancellation_reason || ""

    variables = %{
      "doctor_name" => doctor.last_name,
      "patient_name" => patient_name,
      "starts_at" => starts_at_formatted,
      "cancellation_reason" => cancellation_reason
    }

    render_email(
      "appointment_cancelled_doctor",
      variables,
      {doctor.first_name, doctor_user.email},
      fn ->
        reason_text = if cancellation_reason != "", do: "\nReason: #{cancellation_reason}", else: ""

        new()
        |> to({doctor.first_name, doctor_user.email})
        |> from(from_address())
        |> subject("Appointment cancelled: #{patient_name}")
        |> text_body("""
        Hello Dr. #{doctor.last_name},

        An appointment has been cancelled.

        Details:
        - Patient: #{patient_name}
        - Date & Time: #{starts_at_formatted}#{reason_text}

        Your schedule has been updated accordingly.

        Best regards,
        The Medic Team
        """)
      end
    )
  end

  @doc """
  Builds a reminder email for the patient before their appointment.
  """
  def appointment_reminder(appointment, hours_before) do
    patient = appointment.patient
    doctor = appointment.doctor
    user = patient.user

    starts_at_formatted = format_datetime(appointment.starts_at, appointment.patient_timezone)
    doctor_name = "Dr. #{doctor.first_name} #{doctor.last_name}"

    time_description =
      case hours_before do
        24 -> "tomorrow"
        h when h <= 2 -> "in #{h} hours"
        h -> "in #{h} hours"
      end

    variables = %{
      "patient_name" => patient.first_name,
      "doctor_name" => doctor_name,
      "starts_at" => starts_at_formatted,
      "time_description" => time_description,
      "duration_minutes" => appointment.duration_minutes || 30,
      "consultation_mode" => humanize_mode(appointment.consultation_mode_snapshot),
      "instructions" => if(appointment.consultation_mode_snapshot == "telemedicine", do: "Please ensure you have a stable internet connection for your video consultation.", else: "Please arrive 10 minutes early to complete any paperwork.")
    }

    render_email(
      "appointment_reminder",
      variables,
      {patient.first_name, user.email},
      fn ->
        new()
        |> to({patient.first_name, user.email})
        |> from(from_address())
        |> subject("Reminder: Appointment #{time_description} with #{doctor_name}")
        |> text_body("""
        Hello #{patient.first_name},

        This is a friendly reminder about your upcoming appointment.

        Details:
        - Doctor: #{doctor_name}
        - Date & Time: #{starts_at_formatted}
        - Duration: #{appointment.duration_minutes || 30} minutes
        - Type: #{humanize_mode(appointment.consultation_mode_snapshot)}

        #{variables["instructions"]}

        Need to reschedule? Please contact us as soon as possible.

        Best regards,
        The Medic Team
        """)
      end
    )
  end

  @doc """
  Builds a welcome email for new users from hi@medic.gr.
  """
  def welcome_email(user) do
    variables = %{
      "first_name" => user.first_name
    }

    render_email(
      "welcome_email",
      variables,
      {user.first_name, user.email},
      fn ->
        new()
        |> to({user.first_name, user.email})
        |> from(Config.sender(:general))
        |> subject("Welcome to Medic! 🏥")
        |> text_body("""
        Hello #{user.first_name},

        Welcome to Medic! We're thrilled to have you join our healthcare community.

        With Medic, you can:
        - Search for doctors by specialty and location
        - Book appointments online 24/7
        - Manage your health records in one place
        - Receive appointment reminders

        Ready to get started? Log in to your account and find a doctor near you.

        If you have any questions, feel free to reach out to our support team at support@medic.gr.

        Best regards,
        The Medic Team
        """)
      end
    )
  end

  @doc """
  Builds an email to the doctor when a new appointment request is created (action required).
  """
  def new_appointment_request(appointment) do
    patient = appointment.patient
    doctor = appointment.doctor
    doctor_user = doctor.user

    starts_at_formatted = format_datetime(appointment.starts_at, appointment.doctor_timezone)
    patient_name = "#{patient.first_name} #{patient.last_name}"
    appointment_url = "#{base_url()}/doctor/appointments"

    variables = %{
      "doctor_name" => doctor.last_name,
      "patient_name" => patient_name,
      "starts_at" => starts_at_formatted,
      "duration_minutes" => appointment.duration_minutes || 30,
      "consultation_mode" => humanize_mode(appointment.consultation_mode_snapshot),
      "notes" => appointment.notes || "",
      "action_url" => appointment_url
    }

    render_email(
      "new_appointment_request",
      variables,
      {doctor.first_name, doctor_user.email},
      fn ->
        new()
        |> to({doctor.first_name, doctor_user.email})
        |> from(from_address())
        |> subject("📅 New appointment request from #{patient_name}")
        |> text_body("""
        Hello Dr. #{doctor.last_name},

        You have a new appointment request that requires your action.

        Patient: #{patient_name}
        Requested time: #{starts_at_formatted}
        Duration: #{appointment.duration_minutes || 30} minutes
        Type: #{humanize_mode(appointment.consultation_mode_snapshot)}
        #{if appointment.notes, do: "Notes: #{appointment.notes}", else: ""}

        Please review and respond:
        #{appointment_url}

        You can approve, propose a different time, or decline this request.

        Best regards,
        The Medic Team
        """)
      end
    )
  end

  @doc """
  Builds an email to the patient when their request is declined.
  """
  def appointment_declined(appointment, reason \\ nil) do
    patient = appointment.patient
    doctor = appointment.doctor
    user = patient.user

    doctor_name = "Dr. #{doctor.first_name} #{doctor.last_name}"
    search_url = "#{base_url()}/search"
    reason_str = if is_binary(reason) and reason != "", do: reason, else: ""

    variables = %{
      "patient_name" => patient.first_name,
      "doctor_name" => doctor_name,
      "search_url" => search_url,
      "reason" => reason_str
    }

    render_email(
      "appointment_declined",
      variables,
      {patient.first_name, user.email},
      fn ->
        reason_text = if reason_str != "", do: "\nReason: #{reason_str}", else: ""

        new()
        |> to({patient.first_name, user.email})
        |> from(from_address())
        |> subject("Couldn't confirm your appointment with #{doctor_name}")
        |> text_body("""
        Hello #{patient.first_name},

        Unfortunately, your appointment request with #{doctor_name} couldn't be confirmed.#{reason_text}

        Don't worry — you can easily book another time:
        #{search_url}

        We apologize for any inconvenience.

        Best regards,
        The Medic Team
        """)
      end
    )
  end

  @doc """
  Builds an email to the patient when the doctor proposes a new time.
  """
  def reschedule_proposed(appointment, previous_starts_at, new_starts_at) do
    patient = appointment.patient
    doctor = appointment.doctor
    user = patient.user

    doctor_name = "Dr. #{doctor.first_name} #{doctor.last_name}"
    previous_formatted = format_datetime(previous_starts_at, appointment.patient_timezone)
    new_formatted = format_datetime(new_starts_at, appointment.patient_timezone)
    appointment_url = "#{base_url()}/appointments/#{appointment.id}"

    variables = %{
      "patient_name" => patient.first_name,
      "doctor_name" => doctor_name,
      "previous_starts_at" => previous_formatted,
      "new_starts_at" => new_formatted,
      "action_url" => appointment_url
    }

    render_email(
      "reschedule_proposed",
      variables,
      {patient.first_name, user.email},
      fn ->
        new()
        |> to({patient.first_name, user.email})
        |> from(from_address())
        |> subject("#{doctor_name} proposed a new time for your appointment")
        |> text_body("""
        Hello #{patient.first_name},

        #{doctor_name} has proposed a new time for your appointment.

        Original time: #{previous_formatted}
        New proposed time: #{new_formatted}

        Please review and respond:
        #{appointment_url}

        You can accept the new time or choose a different slot.

        Best regards,
        The Medic Team
        """)
      end
    )
  end

  # --- Private Helpers ---

  defp render_email(template_name, variables, to, fallback_fn) do
    # Define layout wrapper
    wrap_html = fn content ->
      """
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; background-color: #f4f4f5; margin: 0; padding: 0; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { text-align: center; padding: 20px 0; }
          .logo { font-size: 24px; font-weight: bold; color: #0d9488; text-decoration: none; }
          .card { background: #fff; border-radius: 12px; padding: 32px; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06); }
          .footer { text-align: center; margin-top: 24px; font-size: 14px; color: #71717a; }
          .btn { display: inline-block; background-color: #0d9488; color: #fff; padding: 12px 24px; border-radius: 6px; text-decoration: none; font-weight: 600; margin-top: 16px; }
          h1 { margin-top: 0; font-size: 20px; color: #18181b; }
          p { margin-bottom: 16px; }
          .details { background-color: #f8fafc; padding: 16px; border-radius: 8px; margin: 16px 0; }
          .details-item { margin-bottom: 8px; font-size: 14px; }
          .details-label { font-weight: 600; color: #52525b; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <a href="#{base_url()}" class="logo">
              <img src="#{base_url()}/images/logo-medic.png" alt="Medic" height="40" style="display: block; margin: 0 auto; height: 40px;">
            </a>
          </div>
          <div class="card">
            #{content}
          </div>
          <div class="footer">
            <p>&copy; #{Date.utc_today().year} Medic. All rights reserved.</p>
            <p>
              <a href="#{base_url()}" style="color: #71717a;">Website</a> | 
              <a href="#{base_url()}/contact" style="color: #71717a;">Contact Support</a>
            </p>
          </div>
        </div>
      </body>
      </html>
      """
    end

    case Notifications.get_email_template_by_name(template_name) do
      {:ok, %Medic.Notifications.EmailTemplate{} = template} ->
        # Render using the database template
        subject = TemplateRenderer.render(template.subject, variables)
        text_body = TemplateRenderer.render(template.text_body, variables)
        
        # Render HTML body from template, then wrap it
        raw_html = TemplateRenderer.render(template.html_body, variables)
        html_body = wrap_html.(raw_html)
        
        from_tuple = {template.sender_name, template.sender_address}

        new()
        |> to(to)
        |> from(from_tuple)
        |> subject(subject)
        |> text_body(text_body)
        |> html_body(html_body)
        |> put_private(:template_name, template.name)

      _ ->
        # Fallback to hardcoded email
        email = fallback_fn.()
        
        # Wrap the hardcoded HTML body or convert text to HTML if missing
        final_email = 
          if email.html_body do
            html_body(email, wrap_html.(email.html_body))
          else
            # Simple conversion of text to HTML for fallback
            simple_html = email.text_body |> String.split("\n") |> Enum.map(&"<p>#{&1}</p>") |> Enum.join("")
            html_body(email, wrap_html.(simple_html))
          end

        final_email
        |> put_private(:template_name, template_name)
    end
  end

  defp base_url do
    MedicWeb.Endpoint.url()
  end

  defp format_datetime(datetime, timezone) do
    tz = timezone || "Europe/Athens"

    case DateTime.shift_zone(datetime, tz) do
      {:ok, local_dt} ->
        Calendar.strftime(local_dt, "%A, %B %d, %Y at %I:%M %p")

      {:error, _} ->
        Calendar.strftime(datetime, "%A, %B %d, %Y at %I:%M %p UTC")
    end
  end

  defp humanize_mode("in_person"), do: "In-Person Visit"
  defp humanize_mode("telemedicine"), do: "Video Consultation"
  defp humanize_mode(_), do: "Consultation"
end
