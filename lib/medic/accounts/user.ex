defmodule Medic.Accounts.User do
  @moduledoc """
  User schema for authentication.
  Supports both patient and doctor roles.
  """
  use Ash.Resource,
    domain: Medic.Accounts,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "users"
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
      accept [:email, :role, :hashed_password, :confirmed_at, :totp_secret]
    end

    update :update do
      accept [:email, :role, :hashed_password, :confirmed_at, :totp_secret]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :email, :string do
      allow_nil? false
      public? true
    end

    attribute :hashed_password, :string do
      sensitive? true
      # Needed for auth checks
      public? true
    end

    attribute :role, :string do
      default "patient"
      public? true
    end

    attribute :confirmed_at, :utc_datetime do
      public? true
    end

    attribute :totp_secret, :binary do
      sensitive? true
      public? true
    end

    attribute :deleted_at, :utc_datetime_usec do
      public? true
    end

    timestamps()
  end

  relationships do
    has_one :doctor, Medic.Doctors.Doctor
    has_one :patient, Medic.Patients.Patient
  end

  # --- Legacy Ecto Changeset Logic ---

  @roles ~w(patient doctor admin)

  @doc """
  A user changeset for registration.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :role])
    |> validate_email(opts)
    |> validate_password(attrs, opts)
    |> validate_role()
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> update_change(:email, &String.downcase/1)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, attrs, opts) do
    password = attrs["password"] || attrs[:password]

    if password do
      changeset
      |> validate_password_complexity(password)
      |> maybe_hash_password(password, opts)
    else
      add_error(changeset, :password, "can't be blank")
    end
  end

  defp validate_password_complexity(changeset, password) do
    changeset
    |> validate_length_manually(:password, password, min: 8, max: 72)
    |> validate_format_manually(
      :password,
      password,
      ~r/[a-z]/,
      "must contain at least one lowercase letter"
    )
    |> validate_format_manually(
      :password,
      password,
      ~r/[A-Z]/,
      "must contain at least one uppercase letter"
    )
    |> validate_format_manually(
      :password,
      password,
      ~r/[0-9]/,
      "must contain at least one number"
    )
  end

  defp validate_length_manually(changeset, field, value, opts) do
    min = Keyword.get(opts, :min, 0)
    max = Keyword.get(opts, :max, :infinity)
    len = String.length(value)

    cond do
      len < min -> add_error(changeset, field, "should be at least #{min} character(s)")
      len > max -> add_error(changeset, field, "should be at most #{max} character(s)")
      true -> changeset
    end
  end

  defp validate_format_manually(changeset, field, value, regex, message) do
    if value =~ regex do
      changeset
    else
      add_error(changeset, field, message)
    end
  end

  defp validate_role(changeset) do
    changeset
    |> validate_inclusion(:role, @roles)
  end

  defp maybe_hash_password(changeset, password, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)

    if hash_password? && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, Medic.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
  end

  @doc """
  A user changeset for changing the password.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [])
    |> validate_password(attrs, opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.
  """
  def valid_password?(%{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
