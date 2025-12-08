defmodule MedicWeb.DoctorLive.BookingComponent do
  @moduledoc """
  Booking component for scheduling appointments with a doctor.
  Uses the native scheduling engine for slot generation.
  """
  use MedicWeb, :live_component

  alias Medic.Scheduling
  alias Medic.Patients

  @impl true
  def render(assigns) do
    ~H"""
    <div class="booking-component">
      <%= cond do %>
        <% is_nil(@current_user) -> %>
          <%!-- Login Required State --%>
          <div class="text-center py-8">
            <.icon name="hero-calendar" class="w-12 h-12 mx-auto text-base-content/30 mb-4" />
            <h4 class="font-semibold mb-2">Sign in to book an appointment</h4>
            <p class="text-sm text-base-content/70 mb-4">
              Create an account or sign in to schedule your visit
            </p>
            <.link navigate={~p"/login"} class="btn btn-primary">
              <.icon name="hero-arrow-right-on-rectangle" class="w-4 h-4" />
              Sign In
            </.link>
          </div>

        <% @no_availability -> %>
          <%!-- No Availability State --%>
          <div class="alert alert-warning">
            <.icon name="hero-clock" class="w-5 h-5" />
            <span>This doctor hasn't set up their availability yet. Please check back later.</span>
          </div>

        <% true -> %>

        <%!-- Week Navigation --%>
        <div class="flex items-center justify-between mb-4">
          <button
            phx-click="prev_week"
            phx-target={@myself}
            class="btn btn-ghost btn-sm"
            disabled={Date.compare(@week_start, Date.utc_today()) in [:lt, :eq]}
          >
            <.icon name="hero-chevron-left" class="w-4 h-4" />
          </button>
          <span class="font-medium">
            <%= Calendar.strftime(@week_start, "%B %d") %> - <%= Calendar.strftime(@week_end, "%B %d, %Y") %>
          </span>
          <button phx-click="next_week" phx-target={@myself} class="btn btn-ghost btn-sm">
            <.icon name="hero-chevron-right" class="w-4 h-4" />
          </button>
        </div>

        <%!-- Date Picker (Week View) --%>
        <div class="grid grid-cols-7 gap-1 mb-6">
          <%= for {date, day_slots} <- @week_slots do %>
            <% is_today = Date.compare(date, Date.utc_today()) == :eq %>
            <% is_selected = @selected_date && Date.compare(date, @selected_date) == :eq %>
            <% has_slots = length(Enum.filter(day_slots, & &1.status == :free)) > 0 %>
            <% is_past = Date.compare(date, Date.utc_today()) == :lt %>

            <button
              phx-click="select_date"
              phx-target={@myself}
              phx-value-date={Date.to_iso8601(date)}
              class={"flex flex-col items-center p-2 rounded-lg transition-all #{cond do
                is_selected -> "bg-primary text-primary-content"
                is_past -> "bg-base-200 text-base-content/30 cursor-not-allowed"
                has_slots -> "bg-base-200 hover:bg-primary/20 cursor-pointer"
                true -> "bg-base-200 text-base-content/40"
              end}"}
              disabled={is_past || !has_slots}
            >
              <span class="text-xs font-medium">
                <%= Calendar.strftime(date, "%a") %>
              </span>
              <span class={"text-lg font-bold #{if is_today, do: "ring-2 ring-primary ring-offset-2 rounded-full px-1"}"}>
                <%= Calendar.strftime(date, "%d") %>
              </span>
              <%= if has_slots && !is_past do %>
                <span class="text-xs text-success">
                  <%= length(Enum.filter(day_slots, & &1.status == :free)) %> slots
                </span>
              <% end %>
            </button>
          <% end %>
        </div>

        <%!-- Time Slots for Selected Date --%>
        <%= if @selected_date do %>
          <div class="mb-4">
            <h4 class="font-semibold mb-3">
              Available times for <%= Calendar.strftime(@selected_date, "%A, %B %d") %>
            </h4>

            <%= if @available_slots == [] do %>
              <p class="text-sm text-base-content/70">No available slots for this day.</p>
            <% else %>
              <div class="grid grid-cols-4 sm:grid-cols-6 gap-2">
                <%= for slot <- @available_slots do %>
                  <% is_selected_slot = @selected_slot && slot.starts_at == @selected_slot.starts_at %>
                  <%= if slot.status == :free do %>
                    <button
                      phx-click="select_slot"
                      phx-target={@myself}
                      phx-value-starts_at={DateTime.to_iso8601(slot.starts_at)}
                      phx-value-ends_at={DateTime.to_iso8601(slot.ends_at)}
                      class={"btn btn-sm #{if is_selected_slot, do: "btn-primary", else: "btn-outline"}"}
                    >
                      <%= format_time(slot.starts_at) %>
                    </button>
                  <% else %>
                    <button class="btn btn-sm btn-disabled" disabled>
                      <%= format_time(slot.starts_at) %>
                    </button>
                  <% end %>
                <% end %>
              </div>
            <% end %>
          </div>
        <% end %>

        <%!-- Booking Summary & Confirm --%>
        <%= if @selected_slot do %>
          <div class="card bg-primary/10 mt-6">
            <div class="card-body p-4">
              <h4 class="font-semibold mb-2">Appointment Summary</h4>
              <div class="flex justify-between text-sm mb-2">
                <span class="text-base-content/70">Date:</span>
                <span class="font-medium"><%= Calendar.strftime(@selected_date, "%A, %B %d, %Y") %></span>
              </div>
              <div class="flex justify-between text-sm mb-2">
                <span class="text-base-content/70">Time:</span>
                <span class="font-medium"><%= format_time(@selected_slot.starts_at) %> - <%= format_time(@selected_slot.ends_at) %></span>
              </div>
              <%= if @doctor.consultation_fee do %>
                <div class="flex justify-between text-sm mb-2">
                  <span class="text-base-content/70">Consultation Fee:</span>
                  <span class="font-medium text-primary">€<%= @doctor.consultation_fee %></span>
                </div>
              <% end %>

              <div class="divider my-2"></div>

              <div class="form-control mb-4">
                <label class="label">
                  <span class="label-text">Notes (optional)</span>
                </label>
                <textarea
                  phx-change="update_notes"
                  phx-target={@myself}
                  name="notes"
                  class="textarea textarea-bordered h-20"
                  placeholder="Describe your symptoms or reason for visit..."
                ><%= @notes %></textarea>
              </div>

              <button
                phx-click="confirm_booking"
                phx-target={@myself}
                class={"btn btn-primary w-full #{if @booking, do: "loading"}"}
                disabled={@booking}
              >
                <%= if @booking do %>
                  Booking...
                <% else %>
                  <.icon name="hero-check" class="w-4 h-4" />
                  Confirm Appointment
                <% end %>
              </button>
            </div>
          </div>
        <% end %>
      <% end %>

      <%!-- Success Modal --%>
      <%= if @booking_success do %>
        <div class="modal modal-open">
          <div class="modal-box">
            <div class="text-center">
              <div class="text-success text-6xl mb-4">
                <.icon name="hero-check-circle" class="w-16 h-16 mx-auto" />
              </div>
              <h3 class="text-xl font-bold mb-2">Appointment Booked!</h3>
              <p class="text-base-content/70 mb-6">
                Your appointment with Dr. <%= @doctor.last_name %> has been confirmed.
              </p>
              <.link navigate={~p"/dashboard"} class="btn btn-primary">
                View My Appointments
              </.link>
            </div>
          </div>
          <div class="modal-backdrop bg-base-300/80"></div>
        </div>
      <% end %>

      <%!-- Error State --%>
      <%= if @booking_error do %>
        <div class="alert alert-error mt-4">
          <.icon name="hero-exclamation-circle" class="w-5 h-5" />
          <span><%= @booking_error %></span>
          <button phx-click="clear_error" phx-target={@myself} class="btn btn-ghost btn-sm">
            Dismiss
          </button>
        </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok, assign(socket,
      week_start: Date.utc_today(),
      week_end: Date.add(Date.utc_today(), 6),
      week_slots: [],
      selected_date: nil,
      selected_slot: nil,
      available_slots: [],
      notes: "",
      booking: false,
      booking_success: false,
      booking_error: nil,
      no_availability: false
    )}
  end

  @impl true
  def update(assigns, socket) do
    socket = assign(socket, assigns)

    # Load slots if doctor changed or first load
    socket =
      if socket.assigns[:doctor] && (socket.assigns[:week_slots] == [] || assigns[:doctor]) do
        load_week_slots(socket)
      else
        socket
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("prev_week", _, socket) do
    new_start = Date.add(socket.assigns.week_start, -7)

    # Don't go before today
    new_start = if Date.compare(new_start, Date.utc_today()) == :lt do
      Date.utc_today()
    else
      new_start
    end

    socket =
      socket
      |> assign(week_start: new_start, week_end: Date.add(new_start, 6))
      |> load_week_slots()

    {:noreply, socket}
  end

  def handle_event("next_week", _, socket) do
    new_start = Date.add(socket.assigns.week_start, 7)

    socket =
      socket
      |> assign(week_start: new_start, week_end: Date.add(new_start, 6))
      |> load_week_slots()

    {:noreply, socket}
  end

  def handle_event("select_date", %{"date" => date_str}, socket) do
    date = Date.from_iso8601!(date_str)
    slots = get_slots_for_date(socket.assigns.week_slots, date)

    {:noreply, assign(socket,
      selected_date: date,
      available_slots: slots,
      selected_slot: nil
    )}
  end

  def handle_event("select_slot", %{"starts_at" => starts_at, "ends_at" => ends_at}, socket) do
    {:ok, starts_at_dt, _} = DateTime.from_iso8601(starts_at)
    {:ok, ends_at_dt, _} = DateTime.from_iso8601(ends_at)

    slot = %{
      starts_at: starts_at_dt,
      ends_at: ends_at_dt,
      status: :free
    }

    {:noreply, assign(socket, selected_slot: slot)}
  end

  def handle_event("update_notes", %{"notes" => notes}, socket) do
    {:noreply, assign(socket, notes: notes)}
  end

  def handle_event("confirm_booking", _, socket) do
    %{doctor: doctor, current_user: user, selected_slot: slot, notes: notes} = socket.assigns

    socket = assign(socket, booking: true, booking_error: nil)

    # Get or create patient for this user
    patient = case Patients.get_patient_by_user_id(user.id) do
      nil ->
        # Create a patient profile for new users
        {:ok, patient} = Patients.create_patient(user, %{
          first_name: user.email |> String.split("@") |> hd(),
          last_name: "User"
        })
        patient

      patient -> patient
    end

    case Scheduling.book_slot(
      doctor.id,
      patient.id,
      slot.starts_at,
      slot.ends_at,
      notes: notes
    ) do
      {:ok, _appointment} ->
        {:noreply, assign(socket, booking: false, booking_success: true)}

      {:error, :slot_already_booked} ->
        socket =
          socket
          |> assign(booking: false, booking_error: "This slot was just booked. Please choose another time.")
          |> load_week_slots()

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, assign(socket, booking: false, booking_error: "Failed to book appointment. Please try again.")}
    end
  end

  def handle_event("clear_error", _, socket) do
    {:noreply, assign(socket, booking_error: nil)}
  end

  # Private functions

  defp load_week_slots(socket) do
    doctor = socket.assigns.doctor
    start_date = socket.assigns.week_start
    end_date = socket.assigns.week_end

    # Check if doctor has any availability rules
    rules = Scheduling.list_availability_rules(doctor.id)

    if rules == [] do
      assign(socket, no_availability: true, week_slots: [])
    else
      slots_by_day = Scheduling.get_slots_for_range(doctor, start_date, end_date)

      week_slots =
        slots_by_day
        |> Enum.map(fn %{date: date, slots: slots} ->
          {date, slots}
        end)

      assign(socket, week_slots: week_slots, no_availability: false)
    end
  end

  defp get_slots_for_date(week_slots, date) do
    case Enum.find(week_slots, fn {d, _} -> Date.compare(d, date) == :eq end) do
      {_, slots} -> slots
      nil -> []
    end
  end

  defp format_time(datetime) do
    datetime
    |> DateTime.shift_zone!("Europe/Athens")
    |> Calendar.strftime("%H:%M")
  end
end
