defmodule Medic.Workers.IndexDoctor do
  @moduledoc """
  Background worker that syncs doctor documents to Typesense.
  """
  use Oban.Worker, queue: :search, max_attempts: 15

  require Logger
  alias Medic.{Doctors, Search}

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"doctor_id" => doctor_id}}) do
    doctor =
      doctor_id
      |> Doctors.get_doctor!()
      |> Ash.load!([:specialty])

    case Search.index_doctor(doctor) do
      :ok ->
        :ok

      {:error, reason} ->
        Logger.error("Failed to index doctor #{doctor_id}: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    e ->
      Logger.error("IndexDoctor crash for #{doctor_id}: #{Exception.message(e)}")
      {:error, e}
  end
end
