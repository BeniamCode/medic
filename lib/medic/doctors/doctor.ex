defmodule Medic.Doctors.Doctor do
  @moduledoc """
  Doctor profile schema with Cal.com integration and geo-location support.
  """
  use Ash.Resource,
    domain: Medic.Doctors,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset
  require Logger

  postgres do
    table "doctors"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true

      accept [
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
        :specialty_id,
        :user_id,
        :title,
        :pronouns,
        :registration_number,
        :years_of_experience,
        :hospital_affiliation,
        :academic_title,
        :telemedicine_available,
        :board_certifications,
        :sub_specialties,
        :clinical_procedures,
        :conditions_treated,
        :languages,
        :insurance_networks,
        :accessibility_items,
        :awards,
        :publications
      ]

      after_action(&__MODULE__.enqueue_typesense_job/3)
    end

    update :update do
      accept [
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
        :specialty_id,
        :title,
        :pronouns,
        :registration_number,
        :years_of_experience,
        :hospital_affiliation,
        :academic_title,
        :telemedicine_available,
        :board_certifications,
        :sub_specialties,
        :clinical_procedures,
        :conditions_treated,
        :languages,
        :insurance_networks,
        :accessibility_items,
        :awards,
        :publications
      ]

      after_action(&__MODULE__.enqueue_typesense_job/3)
    end

    update :update_rating do
      accept [:rating, :review_count]

      after_action(&__MODULE__.enqueue_typesense_job/3)
    end

    update :update_availability do
      accept [:next_available_slot]

      after_action(&__MODULE__.enqueue_typesense_job/3)
    end

    update :verify do
      require_atomic? false
      accept []

      change fn changeset, _ ->
        Ash.Changeset.force_change_attribute(
          changeset,
          :verified_at,
          DateTime.utc_now() |> DateTime.truncate(:second)
        )
      end

      after_action(&__MODULE__.after_typesense_sync/3)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :first_name, :string, allow_nil?: false
    attribute :last_name, :string, allow_nil?: false
    attribute :bio, :string
    attribute :bio_el, :string
    attribute :profile_image_url, :string
    attribute :location_lat, :float
    attribute :location_lng, :float
    attribute :address, :string
    attribute :city, :string
    attribute :rating, :float, default: 0.0
    attribute :review_count, :integer, default: 0
    attribute :consultation_fee, :decimal
    attribute :next_available_slot, :utc_datetime
    attribute :verified_at, :utc_datetime

    attribute :title, :string
    attribute :pronouns, :string
    attribute :registration_number, :string
    attribute :years_of_experience, :integer
    attribute :hospital_affiliation, :string
    attribute :academic_title, :string
    attribute :telemedicine_available, :boolean, default: false

    attribute :board_certifications, {:array, :string}, default: []
    attribute :sub_specialties, {:array, :string}, default: []
    attribute :clinical_procedures, {:array, :string}, default: []
    attribute :conditions_treated, {:array, :string}, default: []
    attribute :languages, {:array, :string}, default: []
    attribute :insurance_networks, {:array, :string}, default: []
    attribute :accessibility_items, {:array, :string}, default: []
    attribute :awards, {:array, :string}, default: []
    attribute :publications, {:array, :string}, default: []

    timestamps()
  end

  relationships do
    belongs_to :user, Medic.Accounts.User
    belongs_to :specialty, Medic.Doctors.Specialty
    has_many :appointments, Medic.Appointments.Appointment
    has_many :reviews, Medic.Doctors.Review
    has_many :locations, Medic.Doctors.Location
    has_many :appointment_types, Medic.Appointments.AppointmentType
    has_many :schedule_templates, Medic.Scheduling.ScheduleTemplate
    has_many :availability_exceptions, Medic.Scheduling.AvailabilityException
    has_many :time_off_requests, Medic.Scheduling.TimeOffRequest
  end

  calculations do
    calculate :full_name, :string, expr(first_name <> " " <> last_name)

    calculate :localized_bio,
              :string,
              expr(
                if ^arg(:locale) == "el" or ^arg(:locale) == :el do
                  bio_el
                else
                  bio
                end
              ) do
      argument :locale, :term, default: :en
    end
  end

  # --- Legacy Logic ---

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
      :specialty_id,
      :title,
      :pronouns,
      :registration_number,
      :years_of_experience,
      :hospital_affiliation,
      :academic_title,
      :telemedicine_available,
      :board_certifications,
      :sub_specialties,
      :clinical_procedures,
      :conditions_treated,
      :languages,
      :insurance_networks,
      :accessibility_items,
      :awards,
      :publications
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
  def full_name(%{first_name: first, last_name: last}) do
    "#{first} #{last}"
  end

  @doc """
  Returns the localized bio based on locale.
  """
  def localized_bio(%{bio_el: bio_el}, locale)
      when locale in ["el", :el] and not is_nil(bio_el) do
    bio_el
  end

  def localized_bio(%{bio: bio}, _locale), do: bio

  def enqueue_typesense_job(_changeset, {:ok, doctor}, _context) do
    Medic.Doctors.enqueue_index_job(doctor)
    {:ok, doctor}
  end

  def enqueue_typesense_job(_changeset, other, _context), do: other
end
