defmodule Medic.Hospitals.Importer do
  alias Medic.Hospitals

  NimbleCSV.define(SemicolonCSV, separator: ";", escape: "\"")

  def import_from_csv(path) do
    path
    |> File.stream!()
    |> SemicolonCSV.parse_stream(skip_headers: false)
    |> Enum.to_list()
    |> process_rows()
  end

  defp process_rows(rows) do
    # Row 1: Month "ΔΕΚΕΜΒΡΙΟΣ 2025"
    # Row 2: Days
    # Row 3: Headers (Dates)
    [_month_row, _days_row, dates_row | data_rows] = rows

    dates = extract_dates(dates_row)

    Enum.reduce(data_rows, nil, fn row, current_hospital ->
      process_data_row(row, dates, current_hospital)
    end)
  end

  defp extract_dates(row) do
    # Headers start from index 2 (0-based) -> "12/1/25"
    row
    |> Enum.drop(2)
    |> Enum.map(&parse_date/1)
  end

  defp parse_date(date_str) do
    case String.split(date_str, "/") do
      [m, d, y] ->
        year = 2000 + String.to_integer(y)
        Date.new!(year, String.to_integer(m), String.to_integer(d))

      _ ->
        nil
    end
  end

  defp process_data_row([hospital_name, clinic | schedule_values], dates, current_hospital) do
    hospital =
      if hospital_name != "" do
        find_or_create_hospital(hospital_name)
      else
        current_hospital
      end

    if hospital do
      Enum.zip(dates, schedule_values)
      |> Enum.each(fn {date, value} ->
        if date && value != "" do
          create_schedule(hospital, date, clinic)
        end
      end)
    end

    hospital
  end

  defp find_or_create_hospital(name) do
    # Clean up name
    name = String.trim(name)

    case Hospitals.get_hospital_by_name(name) do
      nil ->
        {:ok, hospital} = Hospitals.create_hospital(%{name: name, city: "Thessaloniki"})
        hospital

      hospital ->
        hospital
    end
  end

  defp create_schedule(hospital, date, specialty) do
    # Check if schedule exists for this hospital and date
    case Hospitals.get_schedule(hospital.id, date) do
      nil ->
        Hospitals.create_hospital_schedule(%{
          hospital_id: hospital.id,
          date: date,
          specialties: [specialty]
        })

      schedule ->
        if specialty not in schedule.specialties do
          Hospitals.update_hospital_schedule(schedule, %{
            specialties: schedule.specialties ++ [specialty]
          })
        end
    end
  end
  def import_from_json(json_content) do
    json_content
    |> Jason.decode!()
    |> Enum.each(&process_json_entry/1)
  end

  defp process_json_entry(%{"date" => date_str, "hospital_name" => hospital_name, "specialties" => specialties}) do
    hospital = find_or_create_hospital(hospital_name)
    
    if hospital do
      case Date.from_iso8601(date_str) do
        {:ok, date} ->
          Enum.each(specialties, fn specialty ->
             create_schedule(hospital, date, specialty)
          end)
        _ -> 
          IO.warn("Invalid date format in JSON: #{date_str}")
      end
    end
  end
end
