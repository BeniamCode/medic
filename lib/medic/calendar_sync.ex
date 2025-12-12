defmodule Medic.CalendarSync do
  @moduledoc """
  Calendar synchronization context for managing OAuth connections and busy ranges.
  """

  use Ash.Domain

  resources do
    resource Medic.CalendarSync.CalendarConnection
    resource Medic.CalendarSync.ExternalBusyTime
  end

  alias Medic.CalendarSync.{CalendarConnection, ExternalBusyTime}
  require Ash.Query

  @doc """
  Connects a doctor to an external calendar provider.
  """
  def create_connection(attrs) do
    CalendarConnection
    |> Ash.Changeset.for_create(:create, attrs)
    |> Ash.create()
  end

  def update_connection(%CalendarConnection{} = connection, attrs) do
    connection
    |> Ash.Changeset.for_update(:update, attrs)
    |> Ash.update()
  end

  def list_connections(doctor_id) do
    CalendarConnection
    |> Ash.Query.filter(doctor_id == ^doctor_id)
    |> Ash.read!()
  end

  def upsert_busy_time(attrs) do
    calendar_connection_id =
      Map.get(attrs, :calendar_connection_id) || Map.get(attrs, "calendar_connection_id")

    external_id = Map.get(attrs, :external_id) || Map.get(attrs, "external_id")

    case ExternalBusyTime
         |> Ash.Query.filter(
           calendar_connection_id == ^calendar_connection_id and external_id == ^external_id
         )
         |> Ash.read_one() do
      {:ok, nil} ->
        ExternalBusyTime
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()

      {:ok, busy_time} ->
        busy_time
        |> Ash.Changeset.for_update(:update, attrs)
        |> Ash.update()

      {:error, error} ->
        {:error, error}
    end
  end
end
