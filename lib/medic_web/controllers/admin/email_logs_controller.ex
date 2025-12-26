defmodule MedicWeb.Admin.EmailLogsController do
  use MedicWeb, :controller

  alias Medic.Notifications
  alias Medic.Mailer
  import Swoosh.Email

  def index(conn, _params) do
    logs = Notifications.list_email_logs()
    render_inertia(conn, "Admin/EmailLogs/Index", %{logs: logs})
  end

  def resend(conn, %{"id" => id}) do
    email_log = Notifications.get_email_log!(id)

    # Reconstruct email from log
    # Note: This is an approximation. If variables were complex and logic was needed, 
    # it might not be identical. But we have the rendered body now (if it was logged).
    # If body is missing (old logs), we can't perfectly resend.
    
    if email_log.html_body || email_log.text_body do
       email =
         new()
         |> to(email_log.to)
         |> from({"Medic", "hi@medic.gr"}) # We might want to store 'from' in log too...
         |> subject(email_log.subject)
         |> html_body(email_log.html_body || "")
         |> text_body(email_log.text_body || "")
       
       case Mailer.deliver(email) do
          {:ok, _} ->
             Notifications.create_email_log(%{
                to: email_log.to,
                subject: email_log.subject,
                template_name: email_log.template_name,
                status: :sent,
                triggered_by: "admin_resend",
                html_body: email_log.html_body
             })
             
             conn
             |> put_flash(:info, "Email resent successfully.")
             |> redirect(to: ~p"/medic/email_logs")
             
          {:error, reason} ->
             conn
             |> put_flash(:error, "Failed to resend email: #{inspect(reason)}")
             |> redirect(to: ~p"/medic/email_logs")
       end
    else
        # Fallback? try to re-render if we could? No.
        conn
        |> put_flash(:error, "Cannot resend email: Body not found in log.")
        |> redirect(to: ~p"/medic/email_logs")
    end
  end
end
