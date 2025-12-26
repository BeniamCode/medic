defmodule Medic.Patients.Patient do
  @moduledoc """
  Patient profile schema.
  """
  use Ash.Resource,
    domain: Medic.Patients,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "patients"
    repo Medic.Repo
  end

  actions do
    defaults [:read]

    destroy :destroy do
      primary? true
      soft? true
      change set_attribute(:deleted_at, &DateTime.utc_now/0)
    end

    create :create do
      primary? true

      accept [
        :first_name,
        :last_name,
        :date_of_birth,
        :phone,
        :emergency_contact,
        :profile_image_url,
        :email,
        :preferred_language,
        :preferred_timezone,
        :communication_preferences,
        :user_id
      ]
    end

    update :update do
      accept [
        :first_name,
        :last_name,
        :date_of_birth,
        :phone,
        :emergency_contact,
        :profile_image_url,
        :email,
        :preferred_language,
        :preferred_timezone,
        :communication_preferences
      ]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :first_name, :string
    attribute :last_name, :string
    attribute :date_of_birth, :date
    attribute :phone, :string
    attribute :emergency_contact, :string
    attribute :profile_image_url, :string
    attribute :email, :string
    attribute :preferred_language, :string, default: "en"
    attribute :preferred_timezone, :string
    attribute :communication_preferences, :map, default: %{}
    attribute :doctor_initiated, :boolean, default: false

    attribute :deleted_at, :utc_datetime_usec do
      public? true
    end

    timestamps()
  end

  relationships do
    belongs_to :user, Medic.Accounts.User do
      allow_nil? true
    end
    has_many :appointments, Medic.Appointments.Appointment
  end

  # --- Legacy Logic ---

  @doc false
  def changeset(patient, attrs) do
    patient
    |> cast(attrs, [
      :first_name,
      :last_name,
      :date_of_birth,
      :phone,
      :emergency_contact,
      :profile_image_url,
      :preferred_language,
      :preferred_timezone,
      :communication_preferences
    ])
    |> validate_required([:first_name, :last_name])
    |> validate_inclusion(:preferred_language, ~w(en el))
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
  def full_name(%{first_name: first, last_name: last}) do
    "#{first} #{last}"
  end

  @doc """
  Calculates the patient's age.
  """
  def age(%{date_of_birth: nil}), do: nil

  def age(%{date_of_birth: dob}) do
    today = Date.utc_today()
    years = today.year - dob.year

    if Date.compare(Date.new!(today.year, dob.month, dob.day), today) == :gt do
      years - 1
    else
      years
    end
  end
end
