defmodule MedicWeb.Admin.ReviewLive.Index do
  use MedicWeb, :live_view

  alias Medic.Doctors.Review

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">Review Moderation</h1>
      </div>

      <%= if Enum.empty?(@reviews) do %>
        <div class="text-center py-12 bg-base-100 rounded-box text-base-content/50">
          No reviews found.
        </div>
      <% else %>
        <div class="grid gap-4">
          <%= for review <- @reviews do %>
            <div class="card bg-base-100 shadow-sm border border-base-200">
              <div class="card-body">
                <div class="flex justify-between items-start">
                  <div class="flex gap-4">
                    <div class="avatar placeholder">
                      <div class="bg-neutral text-neutral-content rounded-full w-12">
                        <span><%= String.at(review.patient.first_name, 0) %></span>
                      </div>
                    </div>
                    <div>
                      <div class="font-bold">
                        <%= review.patient.first_name %> <%= review.patient.last_name %>
                        <span class="text-xs font-normal opacity-50">reviewed</span>
                        <%= review.doctor.first_name %> <%= review.doctor.last_name %>
                      </div>
                      <div class="flex items-center gap-1 text-warning text-sm">
                        <%= for _ <- 1..review.rating do %>
                          <.icon name="hero-star-solid" class="size-4" />
                        <% end %>
                        <span class="text-base-content/50 ml-2 text-xs">
                          <%= Calendar.strftime(review.inserted_at, "%b %d, %Y") %>
                        </span>
                      </div>
                    </div>
                  </div>

                  <button
                    class="btn btn-sm btn-ghost text-error"
                    phx-click="delete"
                    phx-value-id={review.id}
                    data-confirm="Are you sure you want to delete this review?"
                  >
                    <.icon name="hero-trash" class="size-4" />
                  </button>
                </div>

                <p class="mt-2 text-sm"><%= review.comment %></p>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # Load all reviews with Patient and Doctor
    reviews =
      Review
      |> Ash.Query.load([:patient, :doctor])
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.read!()

    {:ok, assign(socket, reviews: reviews), layout: {MedicWeb.Layouts, :admin}}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    review = Ash.get!(Review, id)

    case Ash.destroy(review) do
      :ok ->
        # Re-fetch
        reviews =
          Review
          |> Ash.Query.load([:patient, :doctor])
          |> Ash.Query.sort(inserted_at: :desc)
          |> Ash.read!()

        {:noreply, assign(socket, reviews: reviews) |> put_flash(:info, "Review deleted.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not delete review.")}
    end
  end
end
