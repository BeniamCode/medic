defmodule Medic.Emails.Config do
  @moduledoc """
  Email sender configuration for different email types.

  Maps email categories to their sender addresses.
  Credentials are loaded from environment variables in production.
  """

  @doc """
  Returns the sender tuple {name, email} for the given email type.
  """
  def sender(:appointments), do: {"Medic Appointments", "appointments@medic.gr"}
  def sender(:support), do: {"Medic Support", "support@medic.gr"}
  def sender(:sales), do: {"Medic Sales", "sales@medic.gr"}
  def sender(:general), do: {"Medic", "hi@medic.gr"}
  def sender(_), do: sender(:general)

  @doc """
  Returns SMTP credentials for a specific email address.
  Used when we need to send from a specific account.
  """
  def smtp_credentials("appointments@medic.gr") do
    %{
      username: System.get_env("APPOINTMENT_USERNAME") || "appointments@medic.gr",
      password: System.get_env("APPOINTMENTS_SMTP_APP")
    }
  end

  def smtp_credentials("support@medic.gr") do
    %{
      username: System.get_env("SUPPORT_USERNAME") || "support@medic.gr",
      password: System.get_env("SUPPORT_PASSWD")
    }
  end

  def smtp_credentials("sales@medic.gr") do
    %{
      username: System.get_env("SALES_USERNAME") || "sales@medic.gr",
      password: System.get_env("SALES_PASSWD")
    }
  end

  def smtp_credentials("hi@medic.gr") do
    %{
      username: System.get_env("HI_USERNAME") || "hi@medic.gr",
      password: System.get_env("HI_PASSWD")
    }
  end

  def smtp_credentials(_), do: smtp_credentials("hi@medic.gr")
end
