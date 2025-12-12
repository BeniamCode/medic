defmodule MedicWeb.DoctorOnboardingController do
  use MedicWeb, :controller

  alias Decimal
  alias Medic.Doctors
  alias Medic.Doctors.Doctor

  @steps [:welcome, :personal, :specialty, :location, :pricing, :complete]

  def show(conn, params) do
    user = conn.assigns.current_user
    {_doctor, changeset} = load_doctor(user)

    conn
    |> assign(:page_title, dgettext("default", "Doctor Onboarding"))
    |> assign_prop(:step, current_step(params))
    |> assign_prop(:steps, Enum.map(@steps, &Atom.to_string/1))
    |> assign_prop(:doctor, doctor_form(changeset))
    |> assign_prop(:errors, errors_from_changeset(changeset))
    |> assign_prop(:specialties, specialty_options())
    |> render_inertia("Doctor/Onboarding")
  end

  def update(conn, %{"doctor" => doctor_params} = params) do
    user = conn.assigns.current_user
    {doctor, _changeset} = load_doctor(user)

    normalized_params = normalize_params(doctor_params)

    result =
      case Ecto.get_meta(doctor, :state) do
        :built -> Doctors.create_doctor(user, normalized_params)
        _ -> Doctors.update_doctor(doctor, normalized_params)
      end

    step = current_step(params)

    case result do
      {:ok, doctor} ->
        next = next_step(step)
        maybe_verify_doctor(doctor, next)

        if next == :complete do
          redirect(conn, to: ~p"/doctor/schedule")
        else
          redirect(conn, to: ~p"/onboarding/doctor?step=#{Atom.to_string(next)}")
        end

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> assign(:page_title, dgettext("default", "Doctor Onboarding"))
        |> assign_prop(:step, Atom.to_string(step))
        |> assign_prop(:steps, Enum.map(@steps, &Atom.to_string/1))
        |> assign_prop(:doctor, doctor_form(changeset))
        |> assign_prop(:errors, errors_from_changeset(changeset))
        |> assign_prop(:specialties, specialty_options())
        |> render_inertia("Doctor/Onboarding")
    end
  end

  defp maybe_verify_doctor(doctor, :complete) do
    if is_nil(doctor.verified_at) do
      _ = Doctors.verify_doctor(doctor)
    end

    :ok
  end

  defp maybe_verify_doctor(_doctor, _step), do: :ok

  defp load_doctor(user) do
    case Doctors.get_doctor_by_user_id(user.id) do
      nil ->
        doctor = %Doctor{user_id: user.id}
        {doctor, Doctors.change_doctor(doctor)}

      doctor ->
        {doctor, Doctors.change_doctor(doctor)}
    end
  end

  defp specialty_options do
    Doctors.list_specialties()
    |> Enum.map(fn s -> %{id: s.id, name: s.name_en} end)
  end

  defp current_step(%{"step" => step}) do
    step_atom =
      try do
        String.to_existing_atom(step)
      rescue
        _ -> :welcome
      end

    if step_atom in @steps, do: step_atom, else: :welcome
  end

  defp current_step(_), do: :welcome

  defp next_step(:pricing), do: :complete
  defp next_step(:complete), do: :complete

  defp next_step(step) do
    idx = Enum.find_index(@steps, &(&1 == step)) || 0
    Enum.at(@steps, idx + 1, :complete)
  end

  defp doctor_form(changeset) do
    data = Ecto.Changeset.apply_changes(changeset)

    %{
      title: data.title,
      first_name: data.first_name,
      last_name: data.last_name,
      registration_number: data.registration_number,
      years_of_experience: data.years_of_experience,
      specialty_id: data.specialty_id,
      bio: data.bio,
      city: data.city,
      address: data.address,
      telemedicine_available: data.telemedicine_available || false,
      consultation_fee: data.consultation_fee && Decimal.to_float(data.consultation_fee)
    }
  end

  defp normalize_params(params) do
    params
    |> Map.update("telemedicine_available", false, &truthy?/1)
    |> update_decimal("consultation_fee")
  end

  defp truthy?(value) when value in [true, "true", "on", "1"], do: true
  defp truthy?(_), do: false

  defp update_decimal(params, field) do
    case Map.get(params, field) do
      nil -> params
      "" -> Map.put(params, field, nil)
      value -> Map.put(params, field, Decimal.new(value))
    end
  end

  defp errors_from_changeset(%Ecto.Changeset{errors: []}), do: %{}

  defp errors_from_changeset(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
