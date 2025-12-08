defmodule MedicWeb.DoctorLive.Schedule do
  @moduledoc """
  Doctor schedule management using native availability rules.
  """
  use MedicWeb, :live_view

  alias Medic.Repo
  alias Medic.Scheduling
  alias Medic.Scheduling.AvailabilityRule

  @days_of_week 1..7

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-4 md:p-8 space-y-8">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 class="text-3xl font-bold">Manage Schedule</h2>
          <p class="text-base-content/70 mt-1">
            Set your weekly availability for appointments.
          </p>
        </div>
        <div>
          <.link navigate={~p"/dashboard/doctor"} class="btn btn-ghost">
            <.icon name="hero-arrow-left" class="size-4 mr-2" />
            Back to Dashboard
          </.link>
        </div>
      </div>

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
                              <%= Calendar.strftime(rule.start_time, "%H:%M") %> - <%= Calendar.strftime(rule.end_time, "%H:%M") %>
                            </span>
                          </div>
                          <%= if rule.break_start && rule.break_end do %>
                            <div class="text-xs text-base-content/70 flex items-center gap-2">
                              <.icon name="hero-pause" class="size-3" />
                              Break: <%= Calendar.strftime(rule.break_start, "%H:%M") %> - <%= Calendar.strftime(rule.break_end, "%H:%M") %>
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

    <.modal
      :if={@editing_day}
      id="edit-rule-modal"
      show
      on_cancel={JS.push("cancel_edit")}
    >
      <div class="mb-6">
        <h3 class="text-lg font-bold">
          Edit Availability: <%= AvailabilityRule.day_name(@editing_day) %>
        </h3>
        <p class="text-sm text-base-content/70">
          Configure your working hours for this day.
        </p>
      </div>

      <.form
        for={@form}
        phx-submit="save_rule"
        phx-change="validate_rule"
        class="space-y-6"
      >
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

        <div class={if !Ecto.Changeset.get_field(@form.source, :is_active, true), do: "opacity-50 pointer-events-none space-y-4", else: "space-y-4"} >
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
    rules = Scheduling.list_availability_rules(user.doctor.id)
    
    # Map rules by day of week for easy access
    rules_map = Map.new(rules, fn r -> {r.day_of_week, r} end)

    {:ok,
     assign(socket,
       page_title: "Manage Schedule",
       days_of_week: @days_of_week,
       rules: rules_map,
       editing_day: nil,
       form: nil,
       preloaded_user: user
     )}
  end

  @impl true
  def handle_event("edit_rule", %{"day" => day_str}, socket) do
    day = String.to_integer(day_str)
    rule = Map.get(socket.assigns.rules, day) || %AvailabilityRule{
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
       editing_day: day,
       form: to_form(changeset, as: "rule")
     )}
  end

  def handle_event("cancel_edit", _, socket) do
    {:noreply, assign(socket, editing_day: nil, form: nil)}
  end

  def handle_event("validate_rule", %{"rule" => params}, socket) do
    rule = Map.get(socket.assigns.rules, socket.assigns.editing_day) || %AvailabilityRule{}
    
    changeset =
      rule
      |> Scheduling.change_availability_rule(params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, form: to_form(changeset, as: "rule"))}
  end

  def handle_event("test_click", _params, socket) do
    IO.inspect("TEST CLICK RECEIVED", label: "TEST CLICK")
    {:noreply, socket}
  end

  def handle_event("test_main", _params, socket) do
    {:noreply, socket}
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
end
