defmodule Medic.Patients.Patient do
  @moduledoc """
  Patient profile schema.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "patients" do
    belongs_to :user, Medic.Accounts.User
    has_many :appointments, Medic.Appointments.Appointment

    field :first_name, :string
    field :last_name, :string
    field :date_of_birth, :date
    field :phone, :string
    field :emergency_contact, :string
    field :profile_image_url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [
      :first_name,
      :last_name,
      :date_of_birth,
      :phone,
      :emergency_contact,
      :profile_image_url
    ])
    |> validate_required([:first_name, :last_name])
    |> validate_phone()
    |> foreign_key_constraint(:user_id)
  end

  defp validate_phone(changeset) do
    case get_change(changeset, :phone) do
      nil ->
        changeset

      phone ->
        # Greek phone format: +30 followed by 10 digits, or local format
        if Regex.match?(~r/^(\+30)?[26][0-9]{9}$/, String.replace(phone, ~r/[\s\-]/, "")) do
          changeset
        else
          add_error(changeset, :phone, "must be a valid Greek phone number")
        end
    end
  end

  @doc """
  Returns the full name of the patient.
  """
  def full_name(%__MODULE__{first_name: first, last_name: last}) do
    "#{first} #{last}"
  end

  @doc """
  Calculates the patient's age.
  """
  def age(%__MODULE__{date_of_birth: nil}), do: nil

  def age(%__MODULE__{date_of_birth: dob}) do
    today = Date.utc_today()
    years = today.year - dob.year

    if Date.compare(Date.new!(today.year, dob.month, dob.day), today) == :gt do
      years - 1
    else
      years
    end
  end
end
