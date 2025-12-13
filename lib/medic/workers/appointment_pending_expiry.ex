defmodule Medic.Workers.AppointmentPendingExpiry do
  @moduledoc """
  Cancels pending appointments when approval window expires.
  """

  use Oban.Worker, queue: :default, max_attempts: 5

  alias Medic.Appointments

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"appointment_id" => appointment_id}}) do
    appointment = Appointments.get_appointment!(appointment_id)

    cond do
      appointment.status != "pending" ->
        :ok

      is_nil(appointment.pending_expires_at) ->
        :ok

      DateTime.compare(appointment.pending_expires_at, DateTime.utc_now()) == :gt ->
        :ok

      true ->
        Appointments.log_event(appointment.id, "pending_expired", %{
          pending_expires_at: appointment.pending_expires_at
        })

        Appointments.cancel_appointment(appointment, "Approval window expired",
          cancelled_by: :system,
          cancelled_by_actor_type: "system"
        )

        :ok
    end
  rescue
    Ecto.NoResultsError -> :ok
  end
end
