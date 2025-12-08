defmodule MedicWeb.UserLoginLive do
  use MedicWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8 bg-base-200">
      <div class="card w-full max-w-md bg-base-100 shadow-xl">
        <div class="card-body">
          <div class="text-center mb-8">
            <div class="avatar placeholder mb-4">
              <div class="bg-primary/10 text-primary rounded-full w-16">
                <.icon name="hero-heart" class="size-8" />
              </div>
            </div>
            <h2 class="text-3xl font-bold">
              Welcome to Medic
            </h2>
            <p class="mt-2 text-base-content/70">
              Sign in to your account
            </p>
          </div>

          <.form
            for={@form}
            id="login_form"
            action={~p"/login"}
            phx-submit="login"
            phx-trigger-action={@trigger_submit}
            class="space-y-6"
          >
            <%= if @error_message do %>
              <div class="alert alert-error">
                <.icon name="hero-exclamation-circle" class="size-5" />
                <span><%= @error_message %></span>
              </div>
            <% end %>

            <div class="space-y-4">
              <.input
                field={@form[:email]}
                type="email"
                label="Email"
                placeholder="you@example.com"
                required
                autocomplete="email"
              />
              <.input
                field={@form[:password]}
                type="password"
                label="Password"
                placeholder="••••••••"
                required
                autocomplete="current-password"
              />
            </div>

            <div class="form-control">
              <label class="label cursor-pointer justify-start gap-2">
                <input type="checkbox" name="user[remember_me]" class="checkbox checkbox-sm checkbox-primary" />
                <span class="label-text">Remember me</span>
              </label>
            </div>

            <div>
              <.button type="submit" class="btn btn-primary w-full" phx-disable-with="Signing in...">
                <.icon name="hero-arrow-right-on-rectangle" class="size-5 mr-2" />
                Sign In
              </.button>
            </div>
          </.form>

          <div class="divider">or</div>

          <div class="text-center space-y-4">
            <p class="text-base-content/70">Don't have an account?</p>
            <div class="flex gap-4 justify-center">
              <.link navigate={~p"/register"} class="btn btn-outline btn-primary">
                <.icon name="hero-user-plus" class="size-5 mr-2" />
                Patient Sign Up
              </.link>
              <.link navigate={~p"/register/doctor"} class="btn btn-outline">
                <.icon name="hero-identification" class="size-5 mr-2" />
                Doctor Sign Up
              </.link>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")

    {:ok,
     assign(socket,
       form: form,
       page_title: "Sign In",
       trigger_submit: false,
       error_message: nil
     )}
  end

  def handle_event("login", %{"user" => user_params}, socket) do
    %{"email" => email, "password" => password} = user_params

    if Medic.Accounts.get_user_by_email_and_password(email, password) do
      # Valid credentials - trigger the form to submit to the controller
      form = to_form(user_params, as: "user")
      {:noreply, assign(socket, form: form, trigger_submit: true)}
    else
      # Invalid credentials
      form = to_form(user_params, as: "user")
      {:noreply, assign(socket, form: form, error_message: "Invalid email or password")}
    end
  end
end
