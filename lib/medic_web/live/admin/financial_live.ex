defmodule MedicWeb.Admin.FinancialLive do
  use MedicWeb, :live_view

  alias Medic.Appointments.Appointment

  require Ash.Query

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
       <h1 class="text-3xl font-bold">Financial Overview</h1>
       
       <!-- Stats -->
       <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div class="stats shadow bg-base-100">
             <div class="stat">
               <div class="stat-title">Total Revenue (Gross)</div>
               <div class="stat-value text-accent">€<%= Decimal.to_string(@total_revenue) %></div>
               <div class="stat-desc">From completed appointments</div>
             </div>
          </div>
          <div class="stat bg-base-100 shadow rounded-box">
             <div class="stat-title">Platform Fees (15%)</div>
             <div class="stat-value text-primary">€<%= Decimal.round(@platform_fees, 2) %></div>
          </div>
          <div class="stat bg-base-100 shadow rounded-box">
             <div class="stat-title">Payouts Pending</div>
             <div class="stat-value">€<%= Decimal.round(@payouts_pending, 2) %></div>
          </div>
       </div>

       <!-- Transactions Table -->
       <div class="card bg-base-100 shadow-sm">
         <div class="card-body">
            <h2 class="card-title">Recent Transactions</h2>
            <div class="overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Doctor</th>
                    <th>Patient</th>
                    <th>Amount</th>
                    <th>Status</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for txn <- @transactions do %>
                    <tr>
                      <td><%= Calendar.strftime(txn.starts_at, "%b %d, %H:%M") %></td>
                      <td><%= txn.doctor.first_name %> <%= txn.doctor.last_name %></td>
                      <td><%= txn.patient.first_name %> <%= txn.patient.last_name %></td>
                      <td class="font-mono">€<%= txn.doctor.consultation_fee %></td>
                      <td>
                         <div class="badge badge-success badge-outline">Paid</div>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
         </div>
       </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    # Fetch Completed Appointments with loaded Doctor and Patient
    appointments = 
      Appointment
      |> Ash.Query.filter(status == "completed")
      |> Ash.Query.load([:doctor, :patient])
      |> Ash.Query.sort(starts_at: :desc)
      |> Ash.Query.limit(50)
      |> Ash.read!()
    
    # Calculate Total Revenue (Naive: In memory sum)
    # Ideally aggregate in DB
    total_revenue = 
      appointments
      |> Enum.reduce(Decimal.new(0), fn appt, acc -> 
         fee = appt.doctor.consultation_fee || Decimal.new(0)
         Decimal.add(acc, fee)
      end)
      
    platform_fees = Decimal.mult(total_revenue, Decimal.from_float(0.15))
    payouts_pending = Decimal.sub(total_revenue, platform_fees)

    {:ok, 
      assign(socket, 
         transactions: appointments,
         total_revenue: total_revenue,
         platform_fees: platform_fees,
         payouts_pending: payouts_pending
      ), 
      layout: {MedicWeb.Layouts, :admin}
    }
  end
end
