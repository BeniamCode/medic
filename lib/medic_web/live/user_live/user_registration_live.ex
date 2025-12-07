defmodule MedicWeb.UserRegistrationLive do
  use MedicWeb, :live_view

  alias Medic.Accounts
  alias Medic.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div class="text-center">
          <div class="flex justify-center">
            <div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center">
              <.icon name="hero-user-plus" class="w-8 h-8 text-primary" />
            </div>
          </div>
          <h2 class="mt-6 text-3xl font-bold">
            <%= if @role == "doctor", do: "Doctor Registration", else: "Patient Registration" %>
          </h2>
          <p class="mt-2 text-base-content/70">
            Create your Medic account
          </p>
        </div>

        <.form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/login?_action=registered"}
          method="post"
          class="mt-8 space-y-6"
        >
          <div class="space-y-4">
            <.input
              field={@form[:email]}
              type="email"
              label="Email"
              placeholder="you@example.com"
              required
              autocomplete="email"
              phx-debounce="blur"
            />
            <.input
              field={@form[:password]}
              type="password"
              label="Password"
              placeholder="At least 8 characters"
              required
              autocomplete="new-password"
              phx-debounce="blur"
            />

            <div class="text-xs text-base-content/60 space-y-1">
              <p>Password must contain:</p>
              <ul class="list-disc list-inside">
                <li>At least 8 characters</li>
                <li>One uppercase letter</li>
                <li>One lowercase letter</li>
                <li>One number</li>
              </ul>
            </div>
          </div>

          <input type="hidden" name="user[role]" value={@role} />

          <div>
            <.button type="submit" class="w-full btn-primary" phx-disable-with="Creating...">
              <.icon name="hero-check" class="w-5 h-5 mr-2" />
              Create Account
            </.button>
          </div>
        </.form>

        <div class="text-center">
          <p class="text-base-content/70">
            Already have an account?
            <.link navigate={~p"/login"} class="link link-primary">
              Sign In
            </.link>
          </p>
        </div>

        <%= if @role == "patient" do %>
          <div class="text-center">
            <.link navigate={~p"/register/doctor"} class="link text-sm">
              Are you a doctor? Register here →
            </.link>
          </div>
        <% else %>
          <div class="text-center">
            <.link navigate={~p"/register"} class="link text-sm">
              ← Register as a patient
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_params(_params, _url, socket) do
    # Check if this is doctor registration via live_action
    role = if socket.assigns.live_action == :doctor, do: "doctor", else: "patient"

    # Different redirect after login based on role
    login_redirect = if role == "doctor", do: "/onboarding/doctor", else: "/dashboard"

    changeset = Accounts.change_user_registration(%User{}, %{"role" => role})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false, role: role)
      |> assign(login_redirect: login_redirect)
      |> assign(page_title: if(role == "doctor", do: "Doctor Registration", else: "Patient Registration"))
      |> assign_form(changeset)

    {:noreply, socket}
  end

  def handle_event("save", %{"user" => user_params}, socket) do
    user_params = Map.put(user_params, "role", socket.assigns.role)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        changeset = Accounts.change_user_registration(user)

        {:noreply,
         socket
         |> assign(trigger_submit: true)
         |> assign_form(changeset)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    user_params = Map.put(user_params, "role", socket.assigns.role)
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if socket.assigns.check_errors do
      assign(socket, form: form)
    else
      assign(socket, form: form)
    end
  end
end
