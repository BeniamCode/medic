defmodule Medic.HospitalsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medic.Hospitals` context.
  """

  @doc """
  Generate a hospital.
  """
  def hospital_fixture(attrs \\ %{}) do
    {:ok, hospital} =
      attrs
      |> Enum.into(%{
        address: "some address",
        city: "some city",
        location_lat: 120.5,
        location_lng: 120.5,
        name: "some name",
        phone: "some phone"
      })
      |> Medic.Hospitals.create_hospital()

    hospital
  end
end
