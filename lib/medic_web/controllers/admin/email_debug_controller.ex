defmodule MedicWeb.Admin.EmailDebugController do
  use MedicWeb, :controller

  alias Medic.Mailer
  import Swoosh.Email

  def send_test_email(conn, %{"to" => to, "from_type" => from_type}) do
    from_address =
      case from_type do
        "appointments" -> {"Medic Appointments", "appointments@medic.gr"}
        _ -> {"Medic", "hi@medic.gr"}
      end

    email =
      new()
      |> to(to)
      |> from(from_address)
      |> subject("Test Email from Admin Dashboard")
      |> html_body("<h1>Hello World</h1><p>This is a test email triggered from the admin dashboard.</p>")
      |> text_body("Hello World\n\nThis is a test email triggered from the admin dashboard.")

    mailer =
      case from_type do
        "appointments" -> Medic.AppointmentsMailer
        _ -> Medic.Mailer
      end

    case mailer.deliver(email) do
      {:ok, _} ->
        # Log it manually since it's not via the worker?
        # Or blindly trust it. The worker logs it if we usage worker.
        # But here we use Mailer directly like asked?
        # User said "Add debug info in server so we can diagnose".
        # Better to log it.
        
        Medic.Notifications.create_email_log(%{
          to: to,
          subject: email.subject,
          template_name: "manual_test",
          status: :sent,
          triggered_by: "admin_debug"
        })

        conn
        |> put_flash(:info, "Test email sent to #{to}")
        |> redirect(to: ~p"/medic/email_logs")

      {:error, reason} ->
        Medic.Notifications.create_email_log(%{
          to: to,
          subject: email.subject,
          template_name: "manual_test",
          status: :failed,
          error: inspect(reason),
          triggered_by: "admin_debug"
        })

        conn
        |> put_flash(:error, "Failed to send email: #{inspect(reason)}")
        |> redirect(to: ~p"/medic/email_logs")
    end
  end
end
