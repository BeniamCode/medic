defmodule Medic.Accounts do
  @moduledoc """
  The Accounts context for user authentication and management.
  """

  use Ash.Domain

  resources do
    resource Medic.Accounts.User
    resource Medic.Accounts.UserToken
  end

  alias Medic.Repo
  alias Medic.Accounts.{User, UserToken}
  alias Medic.{Doctors, Patients}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil
  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)
  """
  def get_user!(id), do: Repo.get!(User, id)

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def register_user(attrs) do
    role = Map.get(attrs, "role") || Map.get(attrs, :role) || "patient"

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:user, User.registration_changeset(%User{}, attrs), returning: true)
    |> Ecto.Multi.run(:profile, fn _repo, %{user: user} ->
      create_role_profile(user, role)
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
      {:error, :profile, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Registers a user as a doctor.
  """
  def register_doctor(attrs) do
    attrs = Map.put(attrs, "role", "doctor")
    register_user(attrs)
  end

  @doc """
  Registers a user as a patient.
  """
  def register_patient(attrs) do
    attrs = Map.put(attrs, "role", "patient")
    register_user(attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user_registration(user)
      %Ecto.Changeset{data: %User{}}
  """
  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false, validate_email: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}
  """
  def change_user_email(user, attrs \\ %{}) do
    User.email_changeset(user, attrs, validate_email: false)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}
  """
  def change_user_password(user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  @doc """
  Updates the user password.

  ## Examples

      iex> update_user_password(user, "valid password", %{password: ...})
      {:ok, %User{}}

      iex> update_user_password(user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}
  """
  def update_user_password(user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token_attrs} = UserToken.build_session_token(user)

    UserToken
    |> Ash.Changeset.for_create(:create, user_token_attrs)
    |> Ash.create!()

    token
  end

  @doc """
  Gets the user with the given signed token.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)

    query
    |> Repo.one()
    |> maybe_preload_profile()
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.by_token_and_context_query(token, "session"))
    :ok
  end

  defp maybe_preload_profile(nil), do: nil

  defp maybe_preload_profile(user) do
    Repo.preload(user, [:doctor, :patient])
  end

  defp create_role_profile(user, "doctor") do
    {first, last} = inferred_names(user.email, default_last: "Doctor")
    Doctors.create_doctor(user, %{first_name: first, last_name: last})
  end

  defp create_role_profile(user, "patient") do
    {first, last} = inferred_names(user.email, default_last: "Patient")
    Patients.create_patient(user, %{first_name: first, last_name: last})
  end

  defp create_role_profile(_user, _role), do: {:ok, nil}

  defp inferred_names(nil, opts) do
    {Keyword.get(opts, :default_first, "New"), Keyword.get(opts, :default_last, "User")}
  end

  defp inferred_names(email, opts) do
    default_first = Keyword.get(opts, :default_first, "New")
    default_last = Keyword.get(opts, :default_last, "User")

    local_part =
      email
      |> String.split("@")
      |> List.first()
      |> to_string()
      |> String.replace(~r/[^a-zA-Z]+/, " ")

    parts =
      local_part
      |> String.split()
      |> Enum.reject(&(&1 == ""))

    case parts do
      [first, last | _] -> {format_name(first), format_name(last)}
      [single] -> {format_name(single), default_last}
      _ -> {default_first, default_last}
    end
  end

  defp format_name(name) do
    name
    |> String.downcase()
    |> String.capitalize()
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given user.

  ## Examples

      iex> deliver_user_confirmation_instructions(user, &url(~p"/users/confirm/\#{&1}"))
      {:ok, %{to: ..., body: ...}}
  """
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token_attrs} = UserToken.build_email_token(user, "confirm")

      UserToken
      |> Ash.Changeset.for_create(:create, user_token_attrs)
      |> Ash.create!()

      # In production, send actual email via Swoosh
      {:ok, %{to: user.email, url: confirmation_url_fun.(encoded_token)}}
    end
  end

  @doc """
  Confirms a user by the given token.

  If the token matches, the user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_multi(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  defp confirm_user_multi(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, ["confirm"]))
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given user.

  ## Examples

      iex> deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/\#{&1}"))
      {:ok, %{to: ..., body: ...}}
  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token_attrs} = UserToken.build_email_token(user, "reset_password")

    UserToken
    |> Ash.Changeset.for_create(:create, user_token_attrs)
    |> Ash.create!()

    {:ok, %{to: user.email, url: reset_password_url_fun.(encoded_token)}}
  end

  @doc """
  Gets the user by reset password token.
  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password.

  ## Examples

      iex> reset_user_password(user, %{password: "new long password"})
      {:ok, %User{}}

      iex> reset_user_password(user, %{password: "short"})
      {:error, %Ecto.Changeset{}}
  """
  def reset_user_password(user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.password_changeset(user, attrs))
    |> Ecto.Multi.delete_all(:tokens, UserToken.by_user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  ## Role helpers

  @doc """
  Checks if a user is a doctor.
  """
  def doctor?(%User{role: "doctor"}), do: true
  def doctor?(_), do: false

  @doc """
  Checks if a user is a patient.
  """
  def patient?(%User{role: "patient"}), do: true
  def patient?(_), do: false

  @doc """
  Checks if a user is an admin.
  """
  def admin?(%User{role: "admin"}), do: true
  def admin?(_), do: false
end
