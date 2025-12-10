defmodule MedicWeb.Admin.OnDutyLive do
  use MedicWeb, :live_view

  alias Medic.Hospitals
  alias Medic.Hospitals.Importer

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <div class="flex items-center justify-between">
         <h1 class="text-3xl font-bold">On-Duty Schedule Management</h1>
         
         <div class="flex gap-2">
            <!-- Download Sample Button -->
            <a href={"data:text/json;charset=utf-8," <> URI.encode(sample_json())} download="on_duty_sample.json" class="btn btn-outline btn-sm">
               <.icon name="hero-arrow-down-tray" class="w-4 h-4 mr-2"/> Download Sample JSON
            </a>
            
            <button class="btn btn-error btn-outline btn-sm" phx-click="confirm_clear_all">
              <.icon name="hero-trash" class="w-4 h-4 mr-2"/> Clear All Future Schedules
            </button>
         </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Stats Card -->
        <div class="stats shadow bg-base-100 w-full">
          <div class="stat">
            <div class="stat-title">Future On-Duty Days</div>
            <div class="stat-value"><%= @future_schedules_count %></div>
            <div class="stat-desc">Scheduled days from today onwards</div>
          </div>
        </div>

        <!-- Upload Card -->
        <div class="card bg-base-100 shadow-xl">
          <div class="card-body">
            <h2 class="card-title">Upload Schedule</h2>
            <p>Upload a JSON file containing the on-duty schedule.</p>
            
            <form phx-submit="save" phx-change="validate">
              <div class="form-control w-full max-w-xs" phx-drop-target={@uploads.json_file.ref}>
                <.live_file_input upload={@uploads.json_file} class="file-input file-input-bordered w-full max-w-xs" />
              </div>
              
              <div class="mt-4">
                 <%= for entry <- @uploads.json_file.entries do %>
                   <div class="flex items-center gap-2 text-sm">
                     <progress value={entry.progress} max="100" class="progress w-20"></progress>
                     <%= entry.client_name %>
                   </div>
                   <%= for err <- upload_errors(@uploads.json_file, entry) do %>
                     <div class="text-error text-xs"><%= error_to_string(err) %></div>
                   <% end %>
                 <% end %>
              </div>

              <div class="card-actions justify-end mt-4">
                <button type="submit" class="btn btn-primary" disabled={@uploads.json_file.entries == []}>
                   Upload & Process
                </button>
              </div>
            </form>
          </div>
        </div>
      </div>

      <!-- Delete Confirmation Modal -->
      <%= if @show_clear_modal do %>
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50" role="dialog" aria-modal="true">
           <div class="bg-base-100 p-6 rounded-lg shadow-xl max-w-md w-full space-y-4">
             <h3 class="text-lg font-bold text-error">Clear Future Schedules?</h3>
             <p class="py-4">Are you sure you want to delete all on-duty schedules from today onwards? This cannot be undone.</p>
             <div class="modal-action">
               <button class="btn" phx-click="cancel_clear">Cancel</button>
               <button class="btn btn-error" phx-click="clear_all">Yes, Clear All</button>
             </div>
           </div>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign(:page_title, "On-Duty Management")
     |> assign(:show_clear_modal, false)
     |> refresh_stats()
     |> allow_upload(:json_file, accept: ~w(.json), max_entries: 1),
     layout: {MedicWeb.Layouts, :admin}}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    # Consume uploaded entries
    upload_results = 
      consume_uploaded_entries(socket, :json_file, fn %{path: path}, _entry ->
        content = File.read!(path)
        Importer.import_from_json(content)
        {:ok, :imported}
      end)
      
    case upload_results do
      [_] -> 
        {:noreply, 
         socket 
         |> put_flash(:info, "Schedule imported successfully.")
         |> refresh_stats()}
      _ -> 
        {:noreply, socket}
    end
  end

  def handle_event("confirm_clear_all", _, socket) do
    {:noreply, assign(socket, :show_clear_modal, true)}
  end

  def handle_event("cancel_clear", _, socket) do
    {:noreply, assign(socket, :show_clear_modal, false)}
  end

  def handle_event("clear_all", _, socket) do
    # Logic to clear future schedules. 
    # Since we don't have a direct 'clear future' in context, we can implement it here or calling context.
    # For now, using raw query or Ash bulk destroy if possible. 
    # HospitalSchedule does not have bulk destroy action defined, so I'll iterate or add one.
    # To be safe and since Ash supports it, let's use Ash.
    
    require Ash.Query
    today = Date.utc_today()
    
    Medic.Hospitals.HospitalSchedule
    |> Ash.Query.filter(date >= ^today)
    |> Ash.bulk_destroy(:destroy, %{}, strategy: :stream)
    
    {:noreply, 
     socket 
     |> assign(:show_clear_modal, false)
     |> put_flash(:info, "Future schedules cleared.")
     |> refresh_stats()}
  end

  defp refresh_stats(socket) do
    require Ash.Query
    today = Date.utc_today()
    
    count = 
      Medic.Hospitals.HospitalSchedule
      |> Ash.Query.filter(date >= ^today)
      |> Ash.count!()
      
    assign(socket, :future_schedules_count, count)
  end

  defp error_to_string(:too_large), do: "File too large"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"

  defp sample_json do
    """
    [
      {
        "date": "#{Date.utc_today()}",
        "hospital_name": "General Hospital of Athens",
        "specialties": ["Pathology", "Surgery", "Cardiology"]
      },
      {
        "date": "#{Date.utc_today() |> Date.add(1)}",
        "hospital_name": "Hippokratio",
        "specialties": ["Pediatrics", "Orthopedics"]
      }
    ]
    """
  end
end
