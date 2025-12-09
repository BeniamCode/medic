defmodule MedicWeb.DoctorLive.Schedule do
  @moduledoc """
  Doctor schedule management using native availability rules.
  """
  use MedicWeb, :live_view

  alias Medic.Repo
  alias Medic.Scheduling
  alias Medic.Scheduling.AvailabilityRule
  alias Medic.Appointments
  alias Medic.Patients.Patient

  @days_of_week 1..7

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4 md:p-8 space-y-8">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 class="text-3xl font-bold">Manage Schedule</h2>
          <p class="text-base-content/70 mt-1">
            Set your availability and manage upcoming visits.
          </p>
        </div>
        <div>
          <.link navigate={~p"/dashboard/doctor"} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="size-4 mr-2" /> Back to Dashboard
          </.link>
        </div>
      </div>

      <div class="grid gap-8 xl:grid-cols-3">
        <div class="xl:col-span-2">
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body p-0">
              <div class="overflow-x-auto">
                <table class="table table-zebra">
                  <thead>
                    <tr>
                      <th class="w-32">Day</th>
                      <th>Availability</th>
                      <th class="w-24">Status</th>
                      <th class="w-24">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    <%= for day <- @days_of_week do %>
                      <% rule = @rules[day] %>
                      <tr class={if !rule || !rule.is_active, do: "opacity-60"}>
                        <td class="font-bold">
                          <%= AvailabilityRule.day_name(day) %>
                        </td>
                        <td>
                          <%= if rule && rule.is_active do %>
                            <div class="flex flex-col gap-1">
                              <div class="flex items-center gap-2">
                                <.icon name="hero-clock" class="size-4 text-primary" />
                                <span class="font-semibold">
                                  <%= Calendar.strftime(rule.start_time, "%H:%M") %> - <%= Calendar.strftime(
                                    rule.end_time,
                                    "%H:%M"
                                  ) %>
                                </span>
                              </div>
                              <%= if rule.break_start && rule.break_end do %>
                                <div class="text-xs text-base-content/70 flex items-center gap-2">
                                  <.icon name="hero-pause" class="size-3" />
                                  Break: <%= Calendar.strftime(rule.break_start, "%H:%M") %> - <%= Calendar.strftime(
                                    rule.break_end,
                                    "%H:%M"
                                  ) %>
                                </div>
                              <% end %>
                            </div>
                          <% else %>
                            <span class="italic text-base-content/50">Unavailable</span>
                          <% end %>
                        </td>
                        <td>
                          <%= if rule && rule.is_active do %>
                            <div class="badge badge-success badge-sm">Active</div>
                          <% else %>
                            <div class="badge badge-ghost badge-sm">Off</div>
                          <% end %>
                        </td>
                        <td>
                          <button
                            phx-click="edit_rule"
                            phx-value-day={day}
                            class="btn btn-square btn-sm btn-ghost"
                          >
                            <.icon name="hero-pencil-square" class="size-4" />
                            <span class="sr-only">Edit</span>
                          </button>
                        </td>
                      </tr>
                    <% end %>
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>

        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <div class="flex items-center justify-between">
              <div>
                <h3 class="card-title">Upcoming Appointments</h3>
                <p class="text-sm text-base-content/70">Pending & confirmed visits</p>
              </div>
              <div class="badge badge-primary badge-lg">
                <%= length(@upcoming_appointments) %>
              </div>
            </div>

            <%= if @upcoming_appointments == [] do %>
              <div class="text-center py-12 text-base-content/60">
                <.icon name="hero-calendar" class="size-12 mx-auto mb-4" /> No upcoming appointments
              </div>
            <% else %>
              <div class="divide-y divide-base-200">
                <%= for appointment <- @upcoming_appointments do %>
                  <div class="py-4 space-y-3">
                    <div class="flex items-start justify-between gap-4">
                      <div>
                        <p class="font-semibold">
                          <%= patient_name(appointment) %>
                        </p>
                        <p class="text-xs uppercase tracking-wide text-base-content/50">
                          <%= appointment.status |> String.upcase() %>
                          <%= if appointment.appointment_type == "telemedicine" do %>
                            • Telemedicine
                          <% end %>
                        </p>
                      </div>
                      <div class="text-right text-sm">
                        <p class="font-semibold"><%= format_datetime(appointment.starts_at) %></p>
                        <p class="text-xs text-base-content/60">
                          <%= format_duration(appointment) %>
                        </p>
                      </div>
                    </div>

                    <div class="flex justify-end gap-2">
                      <button
                        class="btn btn-ghost btn-sm"
                        phx-click="open_cancel_modal"
                        phx-value-appointment_id={appointment.id}
                      >
                        <.icon name="hero-x-mark" class="size-4" /> Cancel
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>

    <.modal
      :if={@canceling_appointment}
      id="cancel-appointment-modal"
      show
      on_cancel={JS.push("close_cancel_modal")}
      box_class="max-w-xl w-11/12"
    >
      <div class="space-y-4">
        <div>
          <h3 class="text-xl font-bold">Cancel Appointment</h3>
          <p class="text-sm text-base-content/70">
            You're about to cancel the visit with <%= patient_name(@canceling_appointment) %>.
          </p>
        </div>

        <.form for={@cancel_form} phx-submit="cancel_appointment" class="space-y-4">
          <input type="hidden" name="cancellation[appointment_id]" value={@canceling_appointment.id} />
          <.input
            field={@cancel_form[:reason]}
            type="textarea"
            label="Cancellation note (shared with patient)"
            placeholder="e.g., Emergency surgery or clinic closed for maintenance"
            class="h-32"
          />

          <div class="modal-action">
            <button type="button" class="btn" phx-click="close_cancel_modal">Keep Appointment</button>
            <.button type="submit" class="btn btn-error">
              <.icon name="hero-x-mark" class="size-4" /> Cancel Appointment
            </.button>
          </div>
        </.form>
      </div>
    </.modal>

    <.modal
      :if={@editing_day}
      id="edit-rule-modal"
      show
      on_cancel={JS.push("cancel_edit")}
      box_class="max-w-4xl w-11/12"
    >
      <div class="mb-6">
        <h3 class="text-lg font-bold">
          Edit Availability: <%= AvailabilityRule.day_name(@editing_day) %>
        </h3>
        <p class="text-sm text-base-content/70">
          Configure your working hours for this day.
        </p>
      </div>

      <.form for={@form} phx-submit="save_rule" phx-change="validate_rule" class="space-y-6">
        <input type="hidden" name="rule[day_of_week]" value={@editing_day} />
        <input type="hidden" name="rule[doctor_id]" value={@preloaded_user.doctor.id} />

        <div class="form-control border rounded-box p-4">
          <label class="label cursor-pointer justify-start gap-4">
            <input
              type="checkbox"
              name="rule[is_active]"
              class="checkbox checkbox-primary"
              checked={Ecto.Changeset.get_field(@form.source, :is_active, true)}
              value="true"
            />
            <input type="hidden" name="rule[is_active]" value="false" />
            <span class="label-text font-medium">Available on this day</span>
          </label>
        </div>

        <div class={
          if !Ecto.Changeset.get_field(@form.source, :is_active, true),
            do: "opacity-50 pointer-events-none space-y-4",
            else: "space-y-4"
        }>
          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:start_time]} type="time" label="Start Time" />
            <.input field={@form[:end_time]} type="time" label="End Time" />
          </div>

          <div class="divider text-xs uppercase text-base-content/50">Break (Optional)</div>

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:break_start]} type="time" label="Break Start" />
            <.input field={@form[:break_end]} type="time" label="Break End" />
          </div>

          <div class="divider text-xs uppercase text-base-content/50">Settings</div>

          <.input
            field={@form[:slot_duration_minutes]}
            type="number"
            label="Slot Duration (minutes)"
            min="5"
            step="5"
          />
        </div>

        <div class="modal-action">
          <button type="button" phx-click="cancel_edit" class="btn">Cancel</button>
          <.button type="submit" class="btn btn-primary">Save Changes</.button>
        </div>
      </.form>
    </.modal>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    user = Repo.preload(socket.assigns.current_user, :doctor)
    rules = Scheduling.list_availability_rules(user.doctor.id, include_inactive: true)
    upcoming = load_upcoming_appointments(user.doctor.id)

    # Map rules by day of week for easy access
    rules_map = Map.new(rules, fn r -> {r.day_of_week, r} end)

    {:ok,
     assign(socket,
       page_title: "Manage Schedule",
       days_of_week: @days_of_week,
       rules: rules_map,
       editing_day: nil,
       form: nil,
       preloaded_user: user,
       upcoming_appointments: upcoming,
       canceling_appointment: nil,
       cancel_form: nil
     )}
  end

  @impl true
  def handle_event("edit_rule", %{"day" => day_str}, socket) do
    day = String.to_integer(day_str)

    rule =
      Map.get(socket.assigns.rules, day) ||
        %AvailabilityRule{
          doctor_id: socket.assigns.preloaded_user.doctor.id,
          day_of_week: day,
          start_time: ~T[09:00:00],
          end_time: ~T[17:00:00],
          slot_duration_minutes: 30,
          is_active: false
        }

    changeset = Scheduling.change_availability_rule(rule)

    {:noreply,
     assign(socket,
       editing_day: day,
       form: to_form(changeset, as: "rule")
     )}
  end

  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, editing_day: nil, form: nil)}
  end

  def handle_event("validate_rule", %{"rule" => params}, socket) do
    rule = (socket.assigns.form && socket.assigns.form.source.data) || %AvailabilityRule{}

    changeset =
      rule
      |> Scheduling.change_availability_rule(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "rule"))}
  end

  def handle_event("save_rule", %{"rule" => params}, socket) do
    day = socket.assigns.editing_day
    existing_rule = Map.get(socket.assigns.rules, day)

    result =
      if existing_rule do
        Scheduling.update_availability_rule(existing_rule, params)
      else
        Scheduling.create_availability_rule(params)
      end

    case result do
      {:ok, rule} ->
        rules = Map.put(socket.assigns.rules, rule.day_of_week, rule)

        {:noreply,
         socket
         |> assign(rules: rules, editing_day: nil, form: nil)
         |> put_flash(:info, "Availability updated successfully")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset, as: "rule"))}
    end
  end

  def handle_event("open_cancel_modal", %{"appointment_id" => appointment_id}, socket) do
    appointment = Enum.find(socket.assigns.upcoming_appointments, &(&1.id == appointment_id))

    form =
      %{reason: ""}
      |> to_form(as: "cancellation")

    {:noreply, assign(socket, canceling_appointment: appointment, cancel_form: form)}
  end

  def handle_event("close_cancel_modal", _, socket) do
    {:noreply, assign(socket, canceling_appointment: nil, cancel_form: nil)}
  end

  def handle_event("cancel_appointment", %{"cancellation" => params}, socket) do
    appointment = socket.assigns.canceling_appointment
    reason = Map.get(params, "reason")

    case Appointments.cancel_appointment(appointment, reason, cancelled_by: :doctor) do
      {:ok, _appointment} ->
        remaining = Enum.reject(socket.assigns.upcoming_appointments, &(&1.id == appointment.id))

        {:noreply,
         socket
         |> assign(upcoming_appointments: remaining, canceling_appointment: nil, cancel_form: nil)
         |> put_flash(:info, "Appointment cancelled and patient notified")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Unable to cancel appointment right now. Please try again.")}
    end
  end

  defp load_upcoming_appointments(doctor_id) do
    Appointments.list_appointments(
      doctor_id: doctor_id,
      status: ["pending", "confirmed"],
      preload: [:patient],
      upcoming: true
    )
    |> Enum.sort_by(fn appt ->
      if appt.starts_at, do: DateTime.to_unix(appt.starts_at), else: 0
    end)
  end

  defp patient_name(%{patient: %Patient{} = patient}) do
    Patient.full_name(patient)
  end

  defp patient_name(_), do: "Patient"

  defp format_datetime(nil), do: ""

  defp format_datetime(datetime) do
    datetime
    |> DateTime.shift_zone!("Europe/Athens")
    |> Calendar.strftime("%a, %d %b · %H:%M")
  end

  defp format_duration(%{starts_at: nil}), do: ""
  defp format_duration(%{ends_at: nil}), do: ""

  defp format_duration(%{starts_at: starts_at, ends_at: ends_at}) do
    minutes = DateTime.diff(ends_at, starts_at, :minute)
    "#{minutes} min visit"
  end
end
