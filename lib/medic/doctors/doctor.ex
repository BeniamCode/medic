defmodule Medic.Doctors.Doctor do
  @moduledoc """
  Doctor profile schema with Cal.com integration and geo-location support.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "doctors" do
    # Associations
    belongs_to :user, Medic.Accounts.User
    belongs_to :specialty, Medic.Doctors.Specialty
    has_many :appointments, Medic.Appointments.Appointment

    # Profile information
    field :first_name, :string
    field :last_name, :string
    field :bio, :string
    field :bio_el, :string
    field :profile_image_url, :string

    # Location for geo-search
    field :location_lat, :float
    field :location_lng, :float
    field :address, :string
    field :city, :string

    # Ratings and pricing
    field :rating, :float, default: 0.0
    field :review_count, :integer, default: 0
    field :consultation_fee, :decimal

    # Cached availability for fast search
    field :next_available_slot, :utc_datetime

    field :verified_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(doctor, attrs) do
    doctor
    |> cast(attrs, [
      :first_name,
      :last_name,
      :bio,
      :bio_el,
      :profile_image_url,
      :location_lat,
      :location_lng,
      :address,
      :city,
      :consultation_fee,
      :specialty_id
    ])
    |> validate_required([:first_name, :last_name])
    |> validate_number(:consultation_fee, greater_than_or_equal_to: 0)
    |> validate_number(:location_lat, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:location_lng, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> foreign_key_constraint(:user_id)
    |> foreign_key_constraint(:specialty_id)
  end

  @doc """
  Changeset for updating rating (internal use only).
  """
  def rating_changeset(doctor, attrs) do
    doctor
    |> cast(attrs, [:rating, :review_count])
    |> validate_number(:rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
    |> validate_number(:review_count, greater_than_or_equal_to: 0)
  end

  @doc """
  Changeset for updating next available slot (used by Oban job).
  """
  def availability_changeset(doctor, attrs) do
    doctor
    |> cast(attrs, [:next_available_slot])
  end

  @doc """
  Changeset for verifying a doctor.
  """
  def verify_changeset(doctor) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(doctor, verified_at: now)
  end

  @doc """
  Returns the full name of the doctor.
  """
  def full_name(%__MODULE__{first_name: first, last_name: last}) do
    "#{first} #{last}"
  end

  @doc """
  Returns the localized bio based on locale.
  """
  def localized_bio(%__MODULE__{bio_el: bio_el}, locale)
      when locale in ["el", :el] and not is_nil(bio_el) do
    bio_el
  end

  def localized_bio(%__MODULE__{bio: bio}, _locale), do: bio
end
