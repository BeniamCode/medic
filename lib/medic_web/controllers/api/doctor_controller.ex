defmodule MedicWeb.API.DoctorController do
  use MedicWeb, :controller

  alias Medic.Search
  alias Medic.Appreciate.DoctorAppreciationStat
  import Ecto.Query
  alias Medic.Repo

  action_fallback MedicWeb.API.FallbackController

  def index(conn, params) do
    query = params["q"] || "*"
    specialty_slug = normalize_blank(params["specialty"])
    city = normalize_blank(params["city"])
    max_price = parse_int(params["max_price"])
    telemedicine_only = params["telemedicine"] == "true" or params["online"] == "true"
    insurance = normalize_blank(params["insurance"])
    page = parse_int(params["page"]) || 1
    per_page = 20

    opts = [
      query: query,
      specialty: specialty_slug,
      city: city,
      max_price: max_price,
      telemedicine_only: telemedicine_only,
      insurance: insurance,
      verified_only: true,
      page: page,
      per_page: per_page
    ]

    case Search.search_doctors(opts) do
      {:ok, %{results: results, total: total}} ->
        appreciation_counts = appreciation_counts_by_doctor_id(results)
        
        doctors = Enum.map(results, &search_result_to_json(&1, appreciation_counts))

        conn
        |> put_status(:ok)
        |> json(%{
          data: doctors,
          meta: %{
            total: total,
            page: page,
            per_page: per_page
          }
        })

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Search failed: #{inspect(reason)}"})
    end
  end

  def show(conn, %{"id" => id}) do
    case Repo.get(Medic.Doctors.Doctor, id) do
      %Medic.Doctors.Doctor{} = doctor ->
        doctor = Ash.load!(doctor, :specialty)
        conn
        |> put_status(:ok)
        |> json(%{data: doctor_to_json(doctor)})

      nil ->
        {:error, :not_found}
    end
  end

  @doc """
  GET /api/doctors/:id/availability
  Returns available time slots for the doctor.
  """
  def availability(conn, %{"id" => id} = params) do
    case Repo.get(Medic.Doctors.Doctor, id) do
      %Medic.Doctors.Doctor{} = doctor ->
        # Parse date range
        start_date = parse_date(params["start_date"]) || Date.utc_today()
        end_date = parse_date(params["end_date"]) || Date.add(start_date, 7)
        
        # Get availability from scheduling
        days = Medic.Scheduling.get_slots_for_range(doctor, start_date, end_date)
        
        conn
        |> put_status(:ok)
        |> json(%{
          data: %{
            doctor_id: doctor.id,
            start_date: Date.to_iso8601(start_date),
            end_date: Date.to_iso8601(end_date),
            days: Enum.map(days, &availability_day_to_json/1)
          }
        })

      nil ->
        {:error, :not_found}
    end
  end

  defp parse_date(nil), do: nil
  defp parse_date(str) when is_binary(str) do
    case Date.from_iso8601(str) do
      {:ok, date} -> date
      _ -> nil
    end
  end

  @doc """
  GET /api/doctors/:id/appointment_types
  Returns available appointment types for the doctor.
  """
  def appointment_types(conn, %{"id" => id}) do
    case Repo.get(Medic.Doctors.Doctor, id) do
      %Medic.Doctors.Doctor{} = doctor ->
        types = Medic.Appointments.list_appointment_types(doctor.id)
        
        conn
        |> put_status(:ok)
        |> json(%{
          data: Enum.map(types, fn type ->
            %{
              id: type.id,
              name: type.name,
              slug: type.slug,
              duration_minutes: type.duration_minutes,
              price: type.price,
              description: type.description
            }
          end)
        })

      nil ->
        {:error, :not_found}
    end
  end

  defp availability_day_to_json(day) do
    %{
      date: Date.to_iso8601(day.date),
      slots: Enum.map(day.slots || [], fn slot ->
        %{
          starts_at: DateTime.to_iso8601(slot.starts_at),
          ends_at: DateTime.to_iso8601(slot.ends_at),
          status: slot.status
        }
      end)
    }
  end

  defp normalize_blank(value) when value in [nil, ""], do: nil
  defp normalize_blank(value), do: value

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil
  defp parse_int(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      :error -> nil
    end
  end
  defp parse_int(val) when is_integer(val), do: val

  defp appreciation_counts_by_doctor_id(results) do
    doctor_ids = Enum.map(results, & &1.id)

    Repo.all(
      from s in DoctorAppreciationStat,
        where: s.doctor_id in ^doctor_ids,
        select: {s.doctor_id, s.appreciated_total_distinct_patients}
    )
    |> Map.new()
  end

  defp search_result_to_json(result, appreciation_counts) do
    %{
      id: result.id,
      first_name: result.first_name,
      last_name: result.last_name,
      specialty_name: result.specialty_name,
      city: result.city,
      rating: result.rating,
      review_count: result.review_count,
      appreciation_count: Map.get(appreciation_counts, result.id, result.appreciation_count),
      consultation_fee: result.consultation_fee,
      verified: result.verified,
      profile_image_url: result.profile_image_url,
      location_lat: result.location_lat,
      location_lng: result.location_lng,
      address: result.address
    }
  end

  # For detailed view
  defp doctor_to_json(doctor) do
    %{
      id: doctor.id,
      first_name: doctor.first_name,
      last_name: doctor.last_name,
      bio: doctor.bio,
      profile_image_url: doctor.profile_image_url,
      city: doctor.city,
      address: doctor.address,
      zip_code: doctor.zip_code,
      rating: doctor.rating,
      review_count: doctor.review_count,
      consultation_fee: doctor.consultation_fee,
      specialty_id: doctor.specialty_id,
      specialty_name: if(doctor.specialty, do: doctor.specialty.name_en, else: nil)
    }
  end
end
