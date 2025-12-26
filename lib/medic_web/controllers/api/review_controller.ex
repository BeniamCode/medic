defmodule MedicWeb.API.ReviewController do
  @moduledoc """
  Review API controller for mobile app.
  Handles doctor reviews.
  """
  use MedicWeb, :controller

  alias Medic.Doctors
  alias Medic.Patients
  alias Medic.Repo
  import Ecto.Query

  action_fallback MedicWeb.API.FallbackController

  @doc """
  GET /api/doctors/:doctor_id/reviews
  Lists reviews for a doctor.
  """
  def index(conn, %{"doctor_id" => doctor_id} = _params) do
    # Use Review resource directly
    reviews = 
      Medic.Doctors.Review
      |> where([r], r.doctor_id == ^doctor_id)
      |> order_by([r], desc: r.inserted_at)
      |> limit(20)
      |> Repo.all()
      |> Repo.preload(:patient)
    
    conn
    |> put_status(:ok)
    |> json(%{data: Enum.map(reviews, &review_to_json/1)})
  end

  @doc """
  POST /api/doctors/:doctor_id/reviews
  Submit a review for a doctor.
  """
  def create(conn, %{"doctor_id" => doctor_id} = params) do
    user = conn.assigns.current_user
    patient = Patients.get_patient_by_user_id(user.id)
    
    unless patient do
      conn
      |> put_status(:forbidden)
      |> json(%{error: "Only patients can submit reviews"})
    else
      attrs = %{
        doctor_id: doctor_id,
        patient_id: patient.id,
        rating: params["rating"],
        comment: params["comment"]
      }

      result =
        Medic.Doctors.Review
        |> Ash.Changeset.for_create(:create, attrs)
        |> Ash.create()

      case result do
        {:ok, review} ->
          conn
          |> put_status(:created)
          |> json(%{data: review_to_json(review)})
        
        {:error, error} ->
          conn
          |> put_status(:unprocessable_entity)
          |> json(%{error: inspect(error)})
      end
    end
  end

  # --- Private Helpers ---

  defp review_to_json(review) do
    %{
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      is_anonymous: Map.get(review, :is_anonymous, false),
      patient_name: if(!Map.get(review, :is_anonymous, false) && review.patient, do: "#{review.patient.first_name} #{review.patient.last_name}"),
      inserted_at: review.inserted_at && (review.inserted_at |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_iso8601())
    }
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
