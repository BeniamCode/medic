defmodule MedicWeb.Admin.DoctorLive.Index do
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias Medic.Doctors.Doctor

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
        <h1 class="text-3xl font-bold">Doctor Management</h1>
      </div>

      <%= if @live_action == :edit do %>
        <.modal show id="doctor_modal" on_cancel={JS.patch(~p"/medic/doctors")}>
          <.live_component
            module={MedicWeb.Admin.DoctorLive.FormComponent}
            id={@doctor.id}
            title={@page_title}
            action={@live_action}
            doctor={@doctor}
            patch={~p"/medic/doctors"}
          />
        </.modal>
      <% end %>

      <%= if @delete_modal_active do %>
        <div
          class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
          role="dialog"
          aria-modal="true"
        >
          <div class="bg-base-100 p-6 rounded-lg shadow-xl max-w-md w-full space-y-4">
            <h3 class="text-lg font-bold text-error">Confirm Deletion</h3>
            <p>
              Are you sure you want to permanently delete <strong><%= @delete_doctor.first_name %> <%= @delete_doctor.last_name %></strong>?
              This action cannot be undone.
            </p>

            <div class="form-control w-full">
              <label class="label">
                <span class="label-text">
                  Type <strong><%= @delete_doctor.first_name %></strong> to confirm:
                </span>
              </label>
              <input
                type="text"
                class="input input-bordered w-full"
                value={@delete_confirm_value}
                phx-keydown="validate_delete"
                phx-keyup="validate_delete"
              />
            </div>

            <div class="modal-action flex justify-end gap-2">
              <button class="btn" phx-click="cancel_delete">Cancel</button>
              <button
                class="btn btn-error"
                phx-click="confirm_delete"
                disabled={@delete_confirm_value != @delete_doctor.first_name}
              >
                Delete Doctor
              </button>
            </div>
          </div>
        </div>
      <% end %>

      <div class="overflow-x-auto bg-base-100 rounded-box shadow">
        <table class="table">
          <thead>
            <tr>
              <th>Doctor</th>
              <th>Specialty</th>
              <th>Status</th>
              <th>Request Date</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <%= for doctor <- @doctors do %>
              <tr class="hover">
                <td>
                  <div class="flex items-center gap-3">
                    <div class="avatar">
                      <div class="mask mask-squircle w-12 h-12">
                        <img src={doctor.profile_image_url || "/images/default_doctor.png"} />
                      </div>
                    </div>
                    <div>
                      <div class="font-bold"><%= doctor.first_name %> <%= doctor.last_name %></div>
                      <div class="text-sm opacity-50"><%= doctor.city %></div>
                    </div>
                  </div>
                </td>
                <td>
                  <%= if doctor.specialty, do: doctor.specialty.name_en, else: "N/A" %>
                </td>
                <td>
                  <%= if doctor.verified_at do %>
                    <div class="badge badge-success gap-2">Verified</div>
                  <% else %>
                    <div class="badge badge-warning gap-2">Pending</div>
                  <% end %>
                </td>
                <td>
                  <%= Calendar.strftime(doctor.inserted_at, "%b %d, %Y") %>
                </td>
                <td>
                  <div class="flex gap-2">
                    <.link patch={~p"/medic/doctors/#{doctor}/edit"} class="btn btn-xs btn-ghost">
                      Edit
                    </.link>

                    <%= unless doctor.verified_at do %>
                      <button
                        class="btn btn-xs btn-success"
                        phx-click="verify"
                        phx-value-id={doctor.id}
                        data-confirm="Are you sure you want to verify this doctor?"
                      >
                        Approve
                      </button>
                    <% end %>

                    <button
                      class="btn btn-xs btn-error btn-outline"
                      phx-click="prompt_delete"
                      phx-value-id={doctor.id}
                    >
                      Reject
                    </button>
                  </div>
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
    # Load all doctors, verify status irrelevant, order by inserted_atdesc
    doctors =
      Doctors.list_doctors(preload: [:specialty])
      |> Enum.sort_by(& &1.inserted_at, {:desc, Date})

    socket =
      socket
      |> assign(doctors: doctors)
      |> assign(:delete_modal_active, false)
      |> assign(:delete_doctor, nil)
      |> assign(:delete_confirm_value, "")

    {:ok, socket, layout: {MedicWeb.Layouts, :admin}}
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Doctor")
    |> assign(:doctor, Medic.Doctors.get_doctor!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Doctors")
    |> assign(:doctor, nil)
  end

  def handle_event("verify", %{"id" => id}, socket) do
    doctor = Medic.Doctors.get_doctor!(id)

    case Medic.Doctors.verify_doctor(doctor) do
      {:ok, _updated_doctor} ->
        doctors =
          Doctors.list_doctors(preload: [:specialty])
          |> Enum.sort_by(& &1.inserted_at, {:desc, Date})

        {:noreply,
         assign(socket, doctors: doctors) |> put_flash(:info, "Doctor verified successfully.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Could not verify doctor.")}
    end
  end

  def handle_event("prompt_delete", %{"id" => id}, socket) do
    doctor = Medic.Doctors.get_doctor!(id)

    {:noreply,
     socket
     |> assign(:delete_doctor, doctor)
     |> assign(:delete_modal_active, true)
     |> assign(:delete_confirm_value, "")}
  end

  def handle_event("cancel_delete", _, socket) do
    {:noreply,
     socket
     |> assign(:delete_doctor, nil)
     |> assign(:delete_modal_active, false)
     |> assign(:delete_confirm_value, "")}
  end

  def handle_event("validate_delete", %{"value" => value}, socket) do
    {:noreply, assign(socket, :delete_confirm_value, value)}
  end

  def handle_event("confirm_delete", _, socket) do
    doctor = socket.assigns.delete_doctor
    expected_name = doctor.first_name

    if socket.assigns.delete_confirm_value == expected_name do
      case Ash.destroy(doctor) do
        :ok ->
          doctors =
            Doctors.list_doctors(preload: [:specialty])
            |> Enum.sort_by(& &1.inserted_at, {:desc, Date})

          {:noreply,
           socket
           |> assign(doctors: doctors)
           |> assign(:delete_doctor, nil)
           |> assign(:delete_modal_active, false)
           |> put_flash(:info, "Doctor record deleted.")}

        {:error, _} ->
          {:noreply, put_flash(socket, :error, "Could not delete doctor.")}
      end
    else
      {:noreply, put_flash(socket, :error, "Name mismatch. Deletion cancelled.")}
    end
  end
end
