defmodule MedicWeb.PatientProfileController do
  use MedicWeb, :controller

  alias Medic.Patients
  alias Medic.Patients.Patient
  alias Medic.Storage

  @max_image_bytes 5_000_000
  @allowed_content_types ~w(image/jpeg image/png image/webp)

  def show(conn, _params) do
    user = conn.assigns.current_user

    with :ok <- ensure_patient_access(user),
         {:ok, patient, _mode} <- fetch_or_build_patient(user) do
      render_profile(conn, patient, %{})
    else
      {:error, :forbidden} ->
        conn
        |> put_flash(:error, dgettext("default", "Not authorized"))
        |> redirect(to: ~p"/dashboard")

      _ ->
        conn
        |> put_flash(:error, dgettext("default", "Unable to load profile"))
        |> redirect(to: ~p"/dashboard")
    end
  end

  def update(conn, %{"patient" => patient_params}) do
    user = conn.assigns.current_user

    with :ok <- ensure_patient_access(user),
         {:ok, patient, mode} <- fetch_or_build_patient(user) do
      result =
        case mode do
          :new -> Patients.create_patient(user, patient_params)
          :existing -> Patients.update_patient(patient, patient_params)
        end

      case result do
        {:ok, updated} ->
          conn
          |> put_flash(:success, dgettext("default", "Profile updated"))
          |> render_profile(updated, %{})

        {:error, changeset} ->
          patient_for_render = Ecto.Changeset.apply_changes(changeset)

          conn
          |> put_status(:unprocessable_entity)
          |> render_profile(patient_for_render, errors_from_changeset(changeset))
      end
    else
      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> render_inertia("Patient/Profile", %{errors: %{base: ["forbidden"]}})

      _ ->
        conn
        |> put_status(:unprocessable_entity)
        |> render_inertia("Patient/Profile", %{errors: %{base: ["unable_to_load"]}})
    end
  end

  def upload_image(conn, params) do
    user = conn.assigns.current_user
    upload = Map.get(params, "image") || Map.get(params, "file")

    with :ok <- ensure_patient_access(user),
         {:ok, patient} <- fetch_patient_for_upload(user),
         %Plug.Upload{} = upload <- upload,
         :ok <- validate_upload(upload),
         {:ok, url} <- persist_upload(patient.id, upload),
         {:ok, _updated} <- Patients.update_patient(patient, %{profile_image_url: url}) do
      json(conn, %{profile_image_url: url})
    else
      nil ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "missing_file"})

      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "forbidden"})

      {:error, reason} when is_binary(reason) ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: reason})

      {:error, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "unable_to_upload"})

      :error ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "unable_to_upload"})
    end
  end

  defp ensure_patient_access(%{role: role}) when role in ["patient", "admin"], do: :ok
  defp ensure_patient_access(_), do: {:error, :forbidden}

  defp fetch_or_build_patient(user) do
    case Patients.get_patient_by_user_id(user.id) do
      nil -> {:ok, %Patient{user_id: user.id}, :new}
      patient -> {:ok, patient, :existing}
    end
  end

  defp fetch_patient_for_upload(user) do
    case Patients.get_patient_by_user_id(user.id) do
      nil -> {:error, "patient_profile_missing"}
      patient -> {:ok, patient}
    end
  end

  defp render_profile(conn, patient, errors) do
    conn
    |> assign(:page_title, dgettext("default", "Patient Profile"))
    |> assign_prop(:patient, patient_props(patient))
    |> assign_prop(:errors, errors)
    |> render_inertia("Patient/Profile")
  end

  defp patient_props(patient) do
    %{
      id: patient.id || "",
      first_name: patient.first_name,
      last_name: patient.last_name,
      date_of_birth: patient.date_of_birth && Date.to_iso8601(patient.date_of_birth),
      phone: patient.phone,
      emergency_contact: patient.emergency_contact,
      profile_image_url: patient.profile_image_url,
      preferred_language: patient.preferred_language,
      preferred_timezone: patient.preferred_timezone,
      communication_preferences: patient.communication_preferences || %{}
    }
  end

  defp validate_upload(%Plug.Upload{content_type: content_type, path: path}) do
    cond do
      content_type not in @allowed_content_types ->
        {:error, "unsupported_type"}

      not File.exists?(path) ->
        {:error, "missing_tempfile"}

      true ->
        case File.stat(path) do
          {:ok, %{size: size}} when size <= @max_image_bytes -> :ok
          {:ok, _} -> {:error, "too_large"}
          {:error, _} -> {:error, "missing_tempfile"}
        end
    end
  end

  defp persist_upload(patient_id, %Plug.Upload{content_type: content_type, path: path}) do
    ext =
      case content_type do
        "image/jpeg" -> ".jpg"
        "image/png" -> ".png"
        "image/webp" -> ".webp"
        _ -> ".img"
      end

    with {:ok, file_binary} <- File.read(path),
         {:ok, url} <-
           Storage.upload_patient_profile_image(patient_id, file_binary, content_type, ext) do
      {:ok, url}
    else
      {:error, :storage_not_configured} -> {:error, "storage_not_configured"}
      {:error, _} -> {:error, "unable_to_store"}
    end
  end

  defp errors_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
