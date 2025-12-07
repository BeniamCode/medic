defmodule MedicWeb.DoctorLive.Profile do
  @moduledoc """
  Doctor profile editing LiveView.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias Medic.Doctors.Doctor

  def render(assigns) do
    ~H"""
    <div class="max-w-4xl mx-auto py-8 px-4">
      <div class="mb-8">
        <.link navigate={~p"/dashboard/doctor"} class="btn btn-ghost btn-sm mb-4">
          <.icon name="hero-arrow-left" class="w-4 h-4" />
          Πίσω στο Dashboard
        </.link>
        <h1 class="text-2xl font-bold">Επεξεργασία Προφίλ</h1>
        <p class="text-base-content/70">Συμπληρώστε τα στοιχεία σας για να εμφανιστείτε στην αναζήτηση</p>
      </div>

      <.form for={@form} id="doctor-profile-form" phx-change="validate" phx-submit="save" class="space-y-6">
        <%!-- Basic Info Card --%>
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title">Βασικές Πληροφορίες</h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input field={@form[:first_name]} label="Όνομα" placeholder="π.χ. Γιώργος" required />
              <.input field={@form[:last_name]} label="Επώνυμο" placeholder="π.χ. Παπαδόπουλος" required />
            </div>

            <.input
              field={@form[:specialty_id]}
              type="select"
              label="Ειδικότητα"
              prompt="Επιλέξτε ειδικότητα"
              options={@specialty_options}
            />

            <.input
              field={@form[:bio]}
              type="textarea"
              label="Βιογραφικό (Αγγλικά)"
              placeholder="Περιγράψτε την εμπειρία και τις εξειδικεύσεις σας..."
              class="textarea textarea-bordered w-full h-32"
            />
            <.input
              field={@form[:bio_el]}
              type="textarea"
              label="Βιογραφικό (Ελληνικά)"
              placeholder="Περιγράψτε την εμπειρία και τις εξειδικεύσεις σας..."
              class="textarea textarea-bordered w-full h-32"
            />
          </div>
        </div>

        <%!-- Location Card --%>
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-map-pin" class="w-5 h-5 text-primary" />
              Τοποθεσία
            </h2>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <.input field={@form[:address]} label="Διεύθυνση" placeholder="π.χ. Λεωφ. Αλεξάνδρας 15" />
              <.input field={@form[:city]} label="Πόλη" placeholder="π.χ. Αθήνα" />
            </div>
            <p class="text-sm text-base-content/60">
              <.icon name="hero-information-circle" class="w-4 h-4 inline" />
              Οι συντεταγμένες θα υπολογιστούν αυτόματα από τη διεύθυνση
            </p>
          </div>
        </div>

        <%!-- Pricing Card --%>
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <h2 class="card-title">
              <.icon name="hero-currency-euro" class="w-5 h-5 text-primary" />
              Τιμολόγηση
            </h2>
            <.input
              field={@form[:consultation_fee]}
              type="number"
              label="Κόστος Επίσκεψης (€)"
              placeholder="π.χ. 50"
              min="0"
              step="0.01"
            />
          </div>
        </div>


        <div class="flex justify-end gap-4">
          <.link navigate={~p"/dashboard/doctor"} class="btn btn-ghost">
            Ακύρωση
          </.link>
          <.button type="submit" class="btn-primary" phx-disable-with="Αποθήκευση...">
            <.icon name="hero-check" class="w-5 h-5 mr-2" />
            Αποθήκευση
          </.button>
        </div>
      </.form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    doctor = Doctors.get_doctor_by_user_id(user.id)
    specialties = Doctors.list_specialties()

    specialty_options =
      Enum.map(specialties, fn s -> {s.name_el, s.id} end)

    {doctor, changeset} =
      case doctor do
        nil ->
          # Create a new doctor profile for this user
          {:ok, new_doctor} = Doctors.create_doctor(user, %{first_name: "", last_name: ""})
          {new_doctor, Doctors.change_doctor(new_doctor)}

        existing ->
          {existing, Doctors.change_doctor(existing)}
      end

    {:ok,
     assign(socket,
       page_title: "Επεξεργασία Προφίλ",
       doctor: doctor,
       specialty_options: specialty_options,
       form: to_form(changeset)
     )}
  end

  def handle_event("validate", %{"doctor" => params}, socket) do
    changeset =
      socket.assigns.doctor
      |> Doctors.change_doctor(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  def handle_event("save", %{"doctor" => params}, socket) do
    case Doctors.update_doctor(socket.assigns.doctor, params) do
      {:ok, doctor} ->
        # Check if profile is complete and verify if needed
        doctor = maybe_verify_doctor(doctor)
        
        msg = if doctor.verified_at, do: "Το προφίλ ενημερώθηκε και επαληθεύτηκε!", else: "Το προφίλ ενημερώθηκε!"

        {:noreply,
         socket
         |> put_flash(:info, msg)
         |> assign(doctor: doctor, form: to_form(Doctors.change_doctor(doctor)))}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp maybe_verify_doctor(doctor) do
    if is_nil(doctor.verified_at) && profile_complete?(doctor) do
      {:ok, verified_doctor} = Doctors.verify_doctor(doctor)
      verified_doctor
    else
      doctor
    end
  end

  defp profile_complete?(doctor) do
    !is_nil(doctor.first_name) && doctor.first_name != "" &&
    !is_nil(doctor.last_name) && doctor.last_name != "" &&
    !is_nil(doctor.specialty_id) &&
    !is_nil(doctor.city) && doctor.city != ""
  end
end
