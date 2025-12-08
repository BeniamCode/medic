defmodule Medic.HospitalsTest do
  use Medic.DataCase

  alias Medic.Hospitals

  describe "hospitals" do
    alias Medic.Hospitals.Hospital

    import Medic.HospitalsFixtures

    @invalid_attrs %{name: nil, address: nil, city: nil, phone: nil, location_lat: nil, location_lng: nil}

    test "list_hospitals/0 returns all hospitals" do
      hospital = hospital_fixture()
      assert Hospitals.list_hospitals() == [hospital]
    end

    test "get_hospital!/1 returns the hospital with given id" do
      hospital = hospital_fixture()
      assert Hospitals.get_hospital!(hospital.id) == hospital
    end

    test "create_hospital/1 with valid data creates a hospital" do
      valid_attrs = %{name: "some name", address: "some address", city: "some city", phone: "some phone", location_lat: 120.5, location_lng: 120.5}

      assert {:ok, %Hospital{} = hospital} = Hospitals.create_hospital(valid_attrs)
      assert hospital.name == "some name"
      assert hospital.address == "some address"
      assert hospital.city == "some city"
      assert hospital.phone == "some phone"
      assert hospital.location_lat == 120.5
      assert hospital.location_lng == 120.5
    end

    test "create_hospital/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Hospitals.create_hospital(@invalid_attrs)
    end

    test "update_hospital/2 with valid data updates the hospital" do
      hospital = hospital_fixture()
      update_attrs = %{name: "some updated name", address: "some updated address", city: "some updated city", phone: "some updated phone", location_lat: 456.7, location_lng: 456.7}

      assert {:ok, %Hospital{} = hospital} = Hospitals.update_hospital(hospital, update_attrs)
      assert hospital.name == "some updated name"
      assert hospital.address == "some updated address"
      assert hospital.city == "some updated city"
      assert hospital.phone == "some updated phone"
      assert hospital.location_lat == 456.7
      assert hospital.location_lng == 456.7
    end

    test "update_hospital/2 with invalid data returns error changeset" do
      hospital = hospital_fixture()
      assert {:error, %Ecto.Changeset{}} = Hospitals.update_hospital(hospital, @invalid_attrs)
      assert hospital == Hospitals.get_hospital!(hospital.id)
    end

    test "delete_hospital/1 deletes the hospital" do
      hospital = hospital_fixture()
      assert {:ok, %Hospital{}} = Hospitals.delete_hospital(hospital)
      assert_raise Ecto.NoResultsError, fn -> Hospitals.get_hospital!(hospital.id) end
    end

    test "change_hospital/1 returns a hospital changeset" do
      hospital = hospital_fixture()
      assert %Ecto.Changeset{} = Hospitals.change_hospital(hospital)
    end
  end
end
