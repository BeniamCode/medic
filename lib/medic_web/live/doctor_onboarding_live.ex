defmodule MedicWeb.DoctorOnboardingLive do
  @moduledoc """
  Typeform-style multi-step doctor onboarding wizard.
  Full-screen, one question per step, smooth transitions.
  """
  use MedicWeb, :live_view

  alias Medic.Doctors
  alias Medic.Doctors.Doctor
  alias Medic.MedicalTaxonomy

  @steps [:welcome, :personal, :specialty, :location, :pricing, :complete]

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 flex flex-col">
      <%!-- Progress Bar --%>
      <div class="fixed top-0 left-0 right-0 z-50 bg-base-100/80 backdrop-blur-sm border-b border-base-200">
        <div class="max-w-2xl mx-auto px-4 py-3">
          <div class="flex items-center justify-between mb-2">
            <span class="text-sm text-base-content/60">Step <%= step_number(@step) %> of <%= length(@steps) - 1 %></span>
            <span class="text-sm font-bold text-primary"><%= step_progress(@step) %>%</span>
          </div>
          <progress class="progress progress-primary w-full" value={step_progress(@step)} max="100"></progress>
        </div>
      </div>

      <%!-- Main Content --%>
      <div class="flex-1 flex items-center justify-center px-4 pt-20 pb-8">
        <div class="w-full max-w-xl">
          <%= case @step do %>
            <% :welcome -> %>
              <.step_welcome />

            <% :personal -> %>
              <.step_personal form={@form} />

            <% :specialty -> %>
              <.step_specialty form={@form} specialty_options={@specialty_options} />

            <% :location -> %>
              <.step_location form={@form} />

            <% :pricing -> %>
              <.step_pricing form={@form} />

            <% :complete -> %>
              <.step_complete doctor={@doctor} />
          <% end %>
        </div>
      </div>

      <%!-- Navigation --%>
      <%= if @step != :complete do %>
        <div class="fixed bottom-0 left-0 right-0 bg-base-100/80 backdrop-blur-sm border-t border-base-200">
          <div class="max-w-xl mx-auto px-4 py-4 flex items-center justify-between">
            <%= if @step != :welcome do %>
              <button phx-click="prev_step" class="btn btn-ghost">
                <.icon name="hero-arrow-left" class="size-4 mr-2" />
                Back
              </button>
            <% else %>
              <div></div>
            <% end %>

            <button phx-click="next_step" class="btn btn-primary btn-lg">
              <%= if @step == :pricing, do: "Complete Setup", else: "Continue" %>
              <.icon name="hero-arrow-right" class="size-4 ml-2" />
            </button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Step Components

  defp step_welcome(assigns) do
    ~H"""
    <div class="text-center space-y-8 animate-fade-in">
      <div class="avatar placeholder">
        <div class="bg-primary/10 text-primary rounded-full w-24">
          <.icon name="hero-identification" class="size-12" />
        </div>
      </div>

      <div class="space-y-4">
        <h1 class="text-4xl md:text-5xl font-bold leading-tight">
          Welcome to Medic!
        </h1>
        <p class="text-xl text-base-content/70 max-w-md mx-auto">
          Let's set up your doctor profile so patients can find and book appointments with you.
        </p>
      </div>

      <div class="flex flex-wrap justify-center gap-4 text-sm text-base-content/60">
        <div class="badge badge-ghost gap-2 p-3">
          <.icon name="hero-clock" class="size-4" />
          <span>Takes about 2 minutes</span>
        </div>
        <div class="badge badge-ghost gap-2 p-3">
          <.icon name="hero-pencil-square" class="size-4" />
          <span>Edit anytime later</span>
        </div>
      </div>
    </div>
    """
  end

  attr :form, :any, required: true

  defp step_personal(assigns) do
    ~H"""
    <div class="space-y-8 animate-fade-in">
      <div class="text-center space-y-2">
        <h2 class="text-3xl md:text-4xl font-bold">What's your name?</h2>
        <p class="text-lg text-base-content/70">This is how patients will see you.</p>
      </div>

      <.form for={@form} phx-change="validate" class="space-y-6">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div class="form-control">
            <label class="label">
              <span class="label-text text-base font-bold">First Name</span>
            </label>
            <input
              type="text"
              name="doctor[first_name]"
              value={@form[:first_name].value}
              placeholder="e.g., Maria"
              class="input input-lg input-bordered w-full text-lg"
              autofocus
            />
          </div>
          <div class="form-control">
            <label class="label">
              <span class="label-text text-base font-bold">Last Name</span>
            </label>
            <input
              type="text"
              name="doctor[last_name]"
              value={@form[:last_name].value}
              placeholder="e.g., Papadopoulou"
              class="input input-lg input-bordered w-full text-lg"
            />
          </div>
        </div>

        <div class="text-center pt-4">
          <div class="inline-flex items-center gap-2 text-base-content/50 text-sm">
            <.icon name="hero-user-circle" class="size-5" />
            <span>Patients will see: Dr. <%= @form[:first_name].value || "___" %> <%= @form[:last_name].value || "___" %></span>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  attr :form, :any, required: true
  attr :specialty_options, :list, required: true

  defp step_specialty(assigns) do
    ~H"""
    <div class="space-y-8 animate-fade-in">
      <div class="text-center space-y-2">
        <h2 class="text-3xl md:text-4xl font-bold">What's your specialty?</h2>
        <p class="text-lg text-base-content/70">Help patients find the right care.</p>
      </div>

      <.form for={@form} phx-change="validate" class="space-y-6">
        <div class="form-control">
          <select
            name="doctor[specialty_id]"
            class="select select-lg select-bordered w-full text-lg"
          >
            <option value="">Select your specialty...</option>
            <%= for {name, id} <- @specialty_options do %>
              <option value={id} selected={to_string(@form[:specialty_id].value) == to_string(id)}>
                <%= name %>
              </option>
            <% end %>
          </select>
        </div>

        <div class="form-control">
          <label class="label">
            <span class="label-text text-base font-bold">Brief Bio (optional)</span>
          </label>
          <textarea
            name="doctor[bio]"
            placeholder="Tell patients about your experience, approach to care, or areas of focus..."
            class="textarea textarea-bordered w-full h-32 text-base"
          ><%= @form[:bio].value %></textarea>
        </div>
      </.form>
    </div>
    """
  end

  attr :form, :any, required: true

  defp step_location(assigns) do
    ~H"""
    <div class="space-y-8 animate-fade-in">
      <div class="text-center space-y-2">
        <h2 class="text-3xl md:text-4xl font-bold">Where do you practice?</h2>
        <p class="text-lg text-base-content/70">So patients nearby can find you.</p>
      </div>

      <.form for={@form} phx-change="validate" class="space-y-6">
        <div class="form-control">
          <label class="label">
            <span class="label-text text-base font-bold">City</span>
          </label>
          <input
            type="text"
            name="doctor[city]"
            value={@form[:city].value}
            placeholder="e.g., Athens"
            class="input input-lg input-bordered w-full text-lg"
          />
        </div>

        <div class="form-control">
          <label class="label">
            <span class="label-text text-base font-bold">Practice Address (optional)</span>
          </label>
          <input
            type="text"
            name="doctor[address]"
            value={@form[:address].value}
            placeholder="e.g., Kifisias Ave 123"
            class="input input-lg input-bordered w-full text-lg"
          />
        </div>
      </.form>
    </div>
    """
  end

  attr :form, :any, required: true

  defp step_pricing(assigns) do
    ~H"""
    <div class="space-y-8 animate-fade-in">
      <div class="text-center space-y-2">
        <h2 class="text-3xl md:text-4xl font-bold">Set your consultation fee</h2>
        <p class="text-lg text-base-content/70">You can always change this later.</p>
      </div>

      <.form for={@form} phx-change="validate" class="space-y-6">
        <div class="form-control">
          <label class="label">
            <span class="label-text text-base font-bold">Consultation Fee (EUR)</span>
          </label>
          <div class="relative">
            <span class="absolute left-4 top-1/2 -translate-y-1/2 text-2xl text-base-content/50">€</span>
            <input
              type="number"
              name="doctor[consultation_fee]"
              value={@form[:consultation_fee].value}
              placeholder="50"
              min="0"
              step="5"
              class="input input-lg input-bordered w-full text-2xl pl-12"
            />
          </div>
          <label class="label">
            <span class="label-text-alt text-base-content/60">Leave empty if you prefer not to display pricing</span>
          </label>
        </div>
      </.form>
    </div>
    """
  end

  attr :doctor, :any, required: true

  defp step_complete(assigns) do
    ~H"""
    <div class="text-center space-y-8 animate-fade-in">
      <div class="avatar placeholder">
        <div class="bg-success/10 text-success rounded-full w-24">
          <.icon name="hero-check-circle" class="size-16" />
        </div>
      </div>

      <div class="space-y-4">
        <h1 class="text-4xl md:text-5xl font-bold leading-tight">
          You're all set!
        </h1>
        <p class="text-xl text-base-content/70 max-w-md mx-auto">
          Your profile is ready. Now let's set up your availability so patients can book appointments.
        </p>
      </div>

      <div class="card bg-base-100 shadow-xl max-w-sm mx-auto">
        <div class="card-body items-center text-center">
          <div class="avatar placeholder">
            <div class="w-16 rounded-full bg-primary/10 text-primary">
              <span class="text-2xl"><.icon name="hero-user" class="size-8" /></span>
            </div>
          </div>
          <h3 class="text-lg font-bold">Dr. <%= @doctor.first_name %> <%= @doctor.last_name %></h3>
          <%= if @doctor.specialty do %>
            <p class="text-primary font-medium"><%= @doctor.specialty.name_en %></p>
          <% end %>
          <%= if @doctor.city do %>
            <p class="text-sm text-base-content/60"><%= @doctor.city %></p>
          <% end %>
        </div>
      </div>

      <div class="flex flex-col gap-3 max-w-xs mx-auto pt-4">
        <.link navigate={~p"/doctor/schedule"} class="btn btn-primary btn-lg">
          <.icon name="hero-calendar-days" class="size-5 mr-2" />
          Set Your Availability
        </.link>
        <.link navigate={~p"/dashboard/doctor"} class="btn btn-ghost">
          Go to Dashboard
        </.link>
      </div>
    </div>
    """
  end

  # Lifecycle

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    specialties = Doctors.list_specialties()
    specialty_options = Enum.map(specialties, fn s -> {s.name_en, s.id} end)

    # Get or create doctor profile
    doctor = Doctors.get_doctor_by_user_id(user.id)
    
    {doctor, changeset} = 
      if doctor do
        {doctor, Doctors.change_doctor(doctor)}
      else
        {%Doctor{user_id: user.id}, Doctors.change_doctor(%Doctor{user_id: user.id})}
      end

    {:ok,
     assign(socket,
       page_title: "Doctor Onboarding",
       step: :welcome,
       steps: @steps,
       doctor: doctor,
       specialty_options: specialty_options,
       form: to_form(changeset)
     )}
  end

  # Events

  @impl true
  def handle_event("next_step", _, socket) do
    current_idx = Enum.find_index(@steps, &(&1 == socket.assigns.step))
    next_step = Enum.at(@steps, current_idx + 1, :complete)

    # Save progress when moving forward (except from welcome)
    socket = if socket.assigns.step != :welcome do
      save_progress(socket)
    else
      socket
    end

    {:noreply, assign(socket, step: next_step)}
  end

  def handle_event("prev_step", _, socket) do
    current_idx = Enum.find_index(@steps, &(&1 == socket.assigns.step))
    prev_step = Enum.at(@steps, max(0, current_idx - 1), :welcome)
    {:noreply, assign(socket, step: prev_step)}
  end

  def handle_event("validate", %{"doctor" => params}, socket) do
    changeset =
      socket.assigns.doctor
      |> Doctors.change_doctor(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset))}
  end

  # Helpers

  defp save_progress(socket) do
    params = socket.assigns.form.params || %{}
    doctor = socket.assigns.doctor

    result =
      if Ecto.get_meta(doctor, :state) == :built do
        Doctors.create_doctor(socket.assigns.current_user, params)
      else
        Doctors.update_doctor(doctor, params)
      end

    case result do
      {:ok, doctor} ->
        doctor = Medic.Repo.preload(doctor, :specialty)
        assign(socket, doctor: doctor, form: to_form(Doctors.change_doctor(doctor)))

      {:error, changeset} ->
        assign(socket, form: to_form(changeset))
    end
  end

  defp step_number(step) do
    case Enum.find_index(@steps, &(&1 == step)) do
      nil -> 0
      idx -> idx
    end
  end

  defp step_progress(step) do
    total = length(@steps) - 1  # Exclude :complete from progress
    current = step_number(step)
    round(current / total * 100)
  end
end
