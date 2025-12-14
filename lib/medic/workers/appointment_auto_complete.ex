defmodule Medic.Workers.AppointmentAutoComplete do
  @moduledoc """
  Periodically marks ended confirmed appointments as completed.

  Without this, an appointment can fall out of "upcoming" (once it starts)
  but never appear in "completed" (unless something else updates its status).
  """

  use Oban.Worker, queue: :maintenance, max_attempts: 3

  import Ecto.Query

  require Logger

  alias Medic.Appointments.Appointment
  alias Medic.Repo

  @impl true
  def perform(_job) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    {count, _} =
      Repo.update_all(
        from(a in Appointment,
          where: a.status == "confirmed" and a.ends_at <= ^now
        ),
        set: [status: "completed", updated_at: now]
      )

    if count > 0 do
      Logger.info("AppointmentAutoComplete marked #{count} appointments completed")
    end

    :ok
  end
end
