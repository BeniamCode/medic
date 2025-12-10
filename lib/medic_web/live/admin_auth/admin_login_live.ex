defmodule MedicWeb.AdminLoginLive do
  use MedicWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center bg-base-300">
      <div class="card w-full max-w-sm bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="flex justify-center mb-4">
            <div class="bg-primary/10 p-3 rounded-full">
               <.icon name="hero-shield-check" class="size-8 text-primary" />
            </div>
          </div>
          <h2 class="text-2xl font-bold text-center mb-1">Admin Access</h2>
          <p class="text-center text-base-content/60 text-sm mb-6">Restricted Area</p>

          <.form
            for={@form}
            id="admin_login_form"
            action={~p"/login"}
            phx-submit="login"
            phx-trigger-action={@trigger_submit}
            class="space-y-4"
          >
             <%= if @error_message do %>
              <div class="alert alert-error text-sm">
                <span><%= @error_message %></span>
              </div>
            <% end %>

            <.input field={@form[:email]} type="email" placeholder="admin@medic.com" required label="Email" />
            <.input field={@form[:password]} type="password" placeholder="••••••••" required label="Password" />
            
            <div>
               <.button type="submit" class="btn btn-primary w-full">
                 Sign In <.icon name="hero-arrow-right" class="size-4 ml-1" />
               </.button>
            </div>
          </.form>
          
          <div class="mt-4 text-center">
            <.link navigate={~p"/"} class="link link-hover text-xs">Back to Main Site</.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    form = to_form(%{}, as: "user")
    {:ok, assign(socket, form: form, trigger_submit: false, error_message: nil), layout: false}
  end

  def handle_event("login", %{"user" => %{"email" => email, "password" => password} = _params}, socket) do
    # Here we should technically verify if user IS admin before even submitting form,
    # but the Controller handles the session creation.
    # Ideally, we check credentials here or let the controller handle it.
    # We will check if the user exists and has role admin.
    
    user = Medic.Accounts.get_user_by_email_and_password(email, password)

    case user do
      %{role: "admin"} ->
         {:noreply, assign(socket, trigger_submit: true)}
      %{role: _} -> 
         {:noreply, assign(socket, error_message: "Access Denied: Not an admin.")}
      nil ->
         {:noreply, assign(socket, error_message: "Invalid credentials.")}
    end
  end
end
