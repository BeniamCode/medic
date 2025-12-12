defmodule MedicWeb.Admin.PatientLive.Index do
  use MedicWeb, :live_view

  alias Medic.Accounts
  alias Medic.Accounts.User
  require Ash.Query

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">Patient Management</h1>
      </div>

      <%= if @delete_modal_active do %>
        <div
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
          role="dialog"
          aria-modal="true"
        >
          <div class="bg-base-100 p-6 rounded-lg shadow-xl max-w-md w-full space-y-4">
            <h3 class="text-lg font-bold text-error">Confirm Deletion</h3>
            <p>
              Are you sure you want to permanently delete patient <strong><%= @delete_patient.email %></strong>?
              This action cannot be undone.
            </p>

            <div class="form-control w-full">
              <label class="label">
                <span class="label-text">
                  Type <strong><%= @delete_patient.email %></strong> to confirm:
                </span>
              </label>
              <input
                type="text"
                class="input input-bordered w-full"
                value={@delete_confirm_value}
                phx-change="validate_delete"
                #
                Use
                phx-change
                on
                input
                directly
                triggers
                validation
                phx-keyup="validate_delete"
              />
            </div>

            <div class="modal-action flex justify-end gap-2">
              <button class="btn" phx-click="cancel_delete">Cancel</button>
              <button
                class="btn btn-error"
                phx-click="confirm_delete"
                disabled={@delete_confirm_value != @delete_patient.email}
              >
                Delete Patient
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <div class="overflow-x-auto bg-base-100 rounded-box shadow">
        <table class="table">
          <thead>
            <tr>
              <th>Patient</th>
              <th>Email</th>
              <th>Status</th>
              <th>Joined</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for patient <- @patients do %>
              <tr class="hover">
                <td>
                  <div class="flex items-center gap-3">
                    <div class="avatar placeholder">
                      <div class="bg-neutral text-neutral-content rounded-full w-12">
                        <span><%= String.slice(patient.email, 0, 1) |> String.upcase() %></span>
                      </div>
                    </div>
                    <div>
                      <div class="font-bold">
                        <!-- Fallback if we don't have name distinct from email yet -->
                        <%= patient.email %>
                      </div>
                    </div>
                  </div>
                </td>
                <td><%= patient.email %></td>
                <td>
                  <%= if patient.confirmed_at do %>
                    <div class="badge badge-success gap-2">Confirmed</div>
                  <% else %>
                    <div class="badge badge-ghost gap-2">Unconfirmed</div>
                  <% end %>
                </td>
                <td>
                  <%= Calendar.strftime(patient.inserted_at, "%b %d, %Y") %>
                </td>
                <td>
                  <button
                    class="btn btn-xs btn-error btn-outline"
                    phx-click="prompt_delete"
                    phx-value-id={patient.id}
                  >
                    Delete
                  </button>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # Fetch all users with role 'patient'
    patients =
      User
      |> Ash.Query.filter(role == "patient")
      |> Ash.Query.sort(inserted_at: :desc)
      |> Ash.read!()

    socket =
      socket
      |> assign(patients: patients)
      |> assign(:delete_modal_active, false)
      |> assign(:delete_patient, nil)
      |> assign(:delete_confirm_value, "")

    {:ok, socket, layout: {MedicWeb.Layouts, :admin}}
  end

  def handle_event("prompt_delete", %{"id" => id}, socket) do
    patient = Ash.get!(User, id)

    {:noreply,
     socket
     |> assign(:delete_patient, patient)
     |> assign(:delete_modal_active, true)
     |> assign(:delete_confirm_value, "")}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply,
     socket
     |> assign(:delete_patient, nil)
     |> assign(:delete_modal_active, false)
     |> assign(:delete_confirm_value, "")}
  end

  def handle_event("validate_delete", %{"value" => value}, socket) do
    {:noreply, assign(socket, :delete_confirm_value, value)}
  end

  def handle_event("confirm_delete", _, socket) do
    patient = socket.assigns.delete_patient

    if socket.assigns.delete_confirm_value == patient.email do
      case Ash.destroy(patient) do
        :ok ->
          patients =
            User
            |> Ash.Query.filter(role == "patient")
            |> Ash.Query.sort(inserted_at: :desc)
            |> Ash.read!()

          {:noreply,
           assign(socket, patients: patients)
           |> assign(:delete_patient, nil)
           |> assign(:delete_modal_active, false)
           |> put_flash(:info, "Patient account deleted.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not delete patient.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Email mismatch. Deletion cancelled.")}
    end
  end
end
