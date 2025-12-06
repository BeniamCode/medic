defmodule MedicWeb.UserLoginLive do
  use MedicWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8">
      <div class="max-w-md w-full space-y-8">
        <div class="text-center">
          <div class="flex justify-center">
            <div class="w-16 h-16 bg-primary/10 rounded-full flex items-center justify-center">
              <.icon name="hero-heart" class="w-8 h-8 text-primary" />
            </div>
          </div>
          <h2 class="mt-6 text-3xl font-bold">
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
          phx-update="ignore"
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

          <div class="flex items-center justify-between">
            <label class="label cursor-pointer gap-2">
              <input type="checkbox" name="user[remember_me]" class="checkbox checkbox-sm" />
              <span class="label-text">Remember me</span>
            </label>
          </div>

          <div>
            <.button type="submit" class="w-full btn-primary" phx-disable-with="Signing in...">
              <.icon name="hero-arrow-right-on-rectangle" class="w-5 h-5 mr-2" />
              Sign In
            </.button>
          </div>
        </.form>

        <div class="divider">or</div>

        <div class="text-center space-y-4">
          <p class="text-base-content/70">Don't have an account?</p>
          <div class="flex gap-4 justify-center">
            <.link navigate={~p"/register"} class="btn btn-outline btn-primary">
              <.icon name="hero-user-plus" class="w-5 h-5 mr-2" />
              Patient Sign Up
            </.link>
            <.link navigate={~p"/register/doctor"} class="btn btn-outline">
              <.icon name="hero-identification" class="w-5 h-5 mr-2" />
              Doctor Sign Up
            </.link>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    email = Phoenix.Flash.get(socket.assigns.flash, :email)
    form = to_form(%{"email" => email}, as: "user")
    {:ok, assign(socket, form: form, page_title: "Sign In"), temporary_assigns: [form: form]}
  end
end
