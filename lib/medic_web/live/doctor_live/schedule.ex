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
    <div class="flex-1 space-y-4 p-8 pt-6">
      <div class="flex items-center justify-between space-y-2">
        <div>
          <h2 class="text-3xl font-bold tracking-tight">Manage Schedule</h2>
          <p class="text-muted-foreground">
            Set your weekly availability for appointments.
          </p>
        </div>
        <div class="flex items-center space-x-2">
          <.link navigate={~p"/dashboard/doctor"} class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2">
            <.icon name="hero-arrow-left" class="mr-2 h-4 w-4" />
            Back to Dashboard
          </.link>
        </div>
      </div>

      <div class="rounded-md border">
        <div class="relative w-full overflow-auto">
          <table class="w-full caption-bottom text-sm">
            <thead class="[&_tr]:border-b">
              <tr class="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted">
                <th class="h-12 px-4 text-left align-middle font-medium text-muted-foreground w-32">Day</th>
                <th class="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Availability</th>
                <th class="h-12 px-4 text-left align-middle font-medium text-muted-foreground w-24">Status</th>
                <th class="h-12 px-4 text-left align-middle font-medium text-muted-foreground w-24">Actions</th>
              </tr>
            </thead>
            <tbody class="[&_tr:last-child]:border-0">
              <%= for day <- @days_of_week do %>
                <% rule = @rules[day] %>
                <tr class={if rule && rule.is_active, do: "border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted", else: "border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted bg-muted/20 text-muted-foreground"}>
                  <td class="p-4 align-middle font-medium">
                    <%= AvailabilityRule.day_name(day) %>
                  </td>
                  <td class="p-4 align-middle">
                    <%= if rule && rule.is_active do %>
                      <div class="flex flex-col gap-1">
                        <div class="flex items-center gap-2">
                          <.icon name="hero-clock" class="h-4 w-4 text-primary" />
                          <span class="font-semibold">
                            <%= Calendar.strftime(rule.start_time, "%H:%M") %> - <%= Calendar.strftime(rule.end_time, "%H:%M") %>
                          </span>
                        </div>
                        <%= if rule.break_start && rule.break_end do %>
                          <div class="text-xs text-muted-foreground flex items-center gap-2">
                            <.icon name="hero-pause" class="h-3 w-3" />
                            Break: <%= Calendar.strftime(rule.break_start, "%H:%M") %> - <%= Calendar.strftime(rule.break_end, "%H:%M") %>
                          </div>
                        <% end %>
                      </div>
                    <% else %>
                      <span class="italic text-muted-foreground/50">Unavailable</span>
                    <% end %>
                  </td>
                  <td class="p-4 align-middle">
                    <%= if rule && rule.is_active do %>
                      <div class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-primary text-primary-foreground hover:bg-primary/80">
                        Active
                      </div>
                    <% else %>
                      <div class="inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80">
                        Off
                      </div>
                    <% end %>
                  </td>
                  <td class="p-4 align-middle">
                    <button
                      phx-click="edit_rule"
                      phx-value-day={day}
                      class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 hover:bg-accent hover:text-accent-foreground h-8 w-8"
                    >
                      <.icon name="hero-pencil-square" class="h-4 w-4" />
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

    <.modal
      :if={@editing_day}
      id="edit-rule-modal"
      show
      on_cancel={JS.push("cancel_edit")}
    >
      <div class="flex flex-col space-y-1.5 text-center sm:text-left mb-6">
        <h3 class="text-lg font-semibold leading-none tracking-tight">
          Edit Availability: <%= AvailabilityRule.day_name(@editing_day) %>
        </h3>
        <p class="text-sm text-muted-foreground">
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

        <div class="flex items-center space-x-2 rounded-md border p-4">
          <input
            type="checkbox"
            name="rule[is_active]"
            id="rule_is_active"
            class="peer h-4 w-4 shrink-0 rounded-sm border border-primary ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 data-[state=checked]:bg-primary data-[state=checked]:text-primary-foreground"
            checked={Ecto.Changeset.get_field(@form.source, :is_active, true)}
            value="true"
          />
          <input type="hidden" name="rule[is_active]" value="false" />
          <div class="flex-1 space-y-1">
            <label for="rule_is_active" class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
              Available on this day
            </label>
          </div>
        </div>

        <div class={if !Ecto.Changeset.get_field(@form.source, :is_active, true), do: "opacity-50 pointer-events-none space-y-4", else: "space-y-4"} >
          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:start_time]} type="time" label="Start Time" />
            <.input field={@form[:end_time]} type="time" label="End Time" />
          </div>

          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <span class="w-full border-t"></span>
            </div>
            <div class="relative flex justify-center text-xs uppercase">
              <span class="bg-background px-2 text-muted-foreground">Break (Optional)</span>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <.input field={@form[:break_start]} type="time" label="Break Start" />
            <.input field={@form[:break_end]} type="time" label="Break End" />
          </div>

          <div class="relative">
            <div class="absolute inset-0 flex items-center">
              <span class="w-full border-t"></span>
            </div>
            <div class="relative flex justify-center text-xs uppercase">
              <span class="bg-background px-2 text-muted-foreground">Settings</span>
            </div>
          </div>

          <.input
            field={@form[:slot_duration_minutes]}
            type="number"
            label="Slot Duration (minutes)"
            min="5"
            step="5"
          />
        </div>

        <div class="flex items-center justify-end space-x-2 pt-4">
          <button type="button" phx-click="cancel_edit" class="inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 border border-input bg-background hover:bg-accent hover:text-accent-foreground h-10 px-4 py-2">Cancel</button>
          <.button type="submit" class="bg-primary text-primary-foreground hover:bg-primary/90">Save Changes</.button>
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
