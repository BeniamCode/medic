defmodule Medic.Workers.SendWelcomeEmail do
  @moduledoc """
  Oban worker for sending welcome emails to new users.
  """

  use Oban.Worker, queue: :mailers, max_attempts: 5

  alias Medic.Accounts
  alias Medic.Emails
  alias Medic.Mailer

  require Logger

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"user_id" => user_id}}) do
    case Accounts.get_user(user_id) do
      nil ->
        Logger.warning("SendWelcomeEmail: User #{user_id} not found")
        :discard

      user ->
        # Load relationships to get first_name (stored in patient/doctor)
        user = Ash.load!(user, [:patient, :doctor])
        first_name = get_first_name(user)
        
        email = Emails.welcome_email(%{email: user.email, first_name: first_name})

        case Mailer.deliver(email) do
          {:ok, _} ->
            Logger.info("SendWelcomeEmail: Sent welcome email to #{user.email}")
            :ok

          {:error, reason} ->
            Logger.error("SendWelcomeEmail: Failed to send to #{user.email}: #{inspect(reason)}")
            {:error, reason}
        end
    end
  end

  defp get_first_name(%{patient: %{first_name: name}}) when not is_nil(name), do: name
  defp get_first_name(%{doctor: %{first_name: name}}) when not is_nil(name), do: name
  defp get_first_name(%{email: email}), do: email |> String.split("@") |> List.first()

  @doc """
  Enqueues a welcome email for a newly registered user.
  """
  def enqueue(user_id) do
    %{user_id: user_id}
    |> new()
    |> Oban.insert()
  end
end
