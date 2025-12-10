defmodule MedicWeb.Admin.DoctorLive.FormComponent do
  use MedicWeb, :live_component

  alias Medic.Doctors

  def render(assigns) do
    ~H"""
    <div>
      <div class="header">
        <h2 class="text-lg font-bold"><%= @title %></h2>
      </div>

      <.form
        for={@form}
        id="doctor-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4 mt-4"
      >
        <.input field={@form[:first_name]} type="text" label="First Name" />
        <.input field={@form[:last_name]} type="text" label="Last Name" />
        <.input field={@form[:verified_at]} type="datetime-local" label="Verified At (Set to verify)" />
        
        <div class="flex justify-end gap-2">
           <.button type="submit" phx-disable-with="Saving...">Save</.button>
        </div>
      </.form>
    </div>
    """
  end

  def update(%{doctor: doctor} = assigns, socket) do
    changeset = Doctors.change_doctor(doctor)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  def handle_event("validate", %{"doctor" => doctor_params}, socket) do
    changeset =
      socket.assigns.doctor
      |> Doctors.change_doctor(doctor_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"doctor" => doctor_params}, socket) do
    case Doctors.update_doctor(socket.assigns.doctor, doctor_params) do
      {:ok, _doctor} ->
        {:noreply,
         socket
         |> put_flash(:info, "Doctor updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
