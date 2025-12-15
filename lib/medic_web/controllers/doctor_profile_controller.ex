defmodule MedicWeb.DoctorProfileController do
  use MedicWeb, :controller

  alias Medic.Doctors
  alias Medic.Doctors.Doctor
  alias Medic.Doctors.Specialty
  alias Medic.Storage

  @max_image_bytes 5_000_000
  @allowed_content_types ~w(image/jpeg image/png image/webp)

  def show(conn, _params) do
    user = conn.assigns.current_user
    {:ok, doctor, _mode} = fetch_or_build_doctor(user)

    render_profile(conn, doctor, %{})
  end

  def update(conn, %{"doctor" => doctor_params}) do
    user = conn.assigns.current_user

    {:ok, doctor, mode} = fetch_or_build_doctor(user)
    input = map_input_arrays(doctor_params)

    result =
      case mode do
        :new -> Doctors.create_doctor(user, input)
        :existing -> Doctors.update_doctor(doctor, input)
      end

    case result do
      {:ok, updated} ->
        updated = if updated.id, do: Ash.load!(updated, [:specialty]), else: updated

        conn
        |> put_flash(:success, dgettext("default", "Profile updated"))
        |> render_profile(updated, %{})

      {:error, changeset} ->
        doctor_for_render = Ecto.Changeset.apply_changes(changeset)

        conn
        |> put_status(:unprocessable_entity)
        |> render_profile(doctor_for_render, errors_from_changeset(changeset))
    end
  end

  def upload_image(conn, params) do
    upload = Map.get(params, "image") || Map.get(params, "file")

    with {:ok, doctor} <- fetch_doctor_for_upload(conn.assigns.current_user),
         %Plug.Upload{} = upload <- upload,
         :ok <- validate_upload(upload),
         {:ok, url} <- persist_upload(doctor.id, upload),
         {:ok, _updated} <- Doctors.update_doctor(doctor, %{profile_image_url: url}) do
      json(conn, %{profile_image_url: url})
    else
      nil ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "missing_file"})

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

  defp fetch_or_build_doctor(user) do
    case Doctors.get_doctor_by_user_id(user.id) do
      nil -> {:ok, %Doctor{user_id: user.id}, :new}
      doctor -> {:ok, Ash.load!(doctor, [:specialty]), :existing}
    end
  end

  defp fetch_doctor_for_upload(user) do
    case Doctors.get_doctor_by_user_id(user.id) do
      nil -> {:error, "doctor_profile_missing"}
      doctor -> {:ok, Ash.load!(doctor, [:specialty])}
    end
  end

  defp render_profile(conn, doctor, errors) do
    specialties = Doctors.list_specialties()

    doctor = if doctor.id, do: Ash.load!(doctor, [:specialty]), else: doctor

    conn
    |> assign(:page_title, dgettext("default", "Doctor Profile"))
    |> assign_prop(:doctor, doctor_props(doctor))
    |> assign_prop(:specialties, Enum.map(specialties, &specialty_option/1))
    |> assign_prop(:errors, errors)
    |> render_inertia("Doctor/Profile")
  end

  defp doctor_props(doctor) do
    specialty_name =
      case doctor.specialty do
        %Specialty{name_en: name_en} -> name_en
        _ -> nil
      end

    %{
      id: doctor.id || "",
      first_name: doctor.first_name,
      last_name: doctor.last_name,
      title: doctor.title,
      profile_image_url: doctor.profile_image_url,
      academic_title: doctor.academic_title,
      hospital_affiliation: doctor.hospital_affiliation,
      registration_number: doctor.registration_number,
      years_of_experience: doctor.years_of_experience,
      specialty_id: doctor.specialty_id,
      specialty_name: specialty_name,
      bio: doctor.bio,
      bio_el: doctor.bio_el,
      address: doctor.address,
      zip_code: doctor.zip_code,
      neighborhood: doctor.neighborhood,
      city: doctor.city,
      location_lat: doctor.location_lat,
      location_lng: doctor.location_lng,
      telemedicine_available: doctor.telemedicine_available,
      consultation_fee: doctor.consultation_fee && Decimal.to_float(doctor.consultation_fee),
      board_certifications: doctor.board_certifications || [],
      languages: doctor.languages || [],
      insurance_networks: doctor.insurance_networks || [],
      sub_specialties: doctor.sub_specialties || [],
      clinical_procedures: doctor.clinical_procedures || [],
      conditions_treated: doctor.conditions_treated || []
    }
  end

  defp specialty_option(%Specialty{id: id, name_en: name_en}) do
    %{id: id, name: name_en}
  end

  defp map_input_arrays(params) do
    params
    |> Map.update("board_certifications", [], &comma_split/1)
    |> Map.update("languages", [], &comma_split/1)
    |> Map.update("insurance_networks", [], &comma_split/1)
    |> Map.update("sub_specialties", [], &comma_split/1)
    |> Map.update("clinical_procedures", [], &comma_split/1)
    |> Map.update("conditions_treated", [], &comma_split/1)
    |> update_decimal("consultation_fee")
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

  defp persist_upload(doctor_id, %Plug.Upload{content_type: content_type, path: path}) do
    ext =
      case content_type do
        "image/jpeg" -> ".jpg"
        "image/png" -> ".png"
        "image/webp" -> ".webp"
        _ -> ".img"
      end

    with {:ok, file_binary} <- File.read(path),
         {:ok, url} <-
           Storage.upload_doctor_profile_image(doctor_id, file_binary, content_type, ext) do
      {:ok, url}
    else
      {:error, :storage_not_configured} -> {:error, "storage_not_configured"}
      {:error, _} -> {:error, "unable_to_store"}
    end
  end

  defp comma_split(value) when is_binary(value) do
    value
    |> String.split([",", "\n"], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp comma_split(value) when is_list(value), do: value
  defp comma_split(_), do: []

  defp update_decimal(params, field) do
    case Map.get(params, field) do
      nil -> params
      "" -> Map.put(params, field, nil)
      value -> Map.put(params, field, Decimal.new(value))
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
