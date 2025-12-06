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
            <%= if @role == "doctor", do: "Εγγραφή Γιατρού", else: "Εγγραφή Ασθενή" %>
          </h2>
          <p class="mt-2 text-base-content/70">
            Δημιουργήστε τον λογαριασμό σας στο Medic
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
              label="Κωδικός"
              placeholder="Τουλάχιστον 8 χαρακτήρες"
              required
              autocomplete="new-password"
              phx-debounce="blur"
            />

            <div class="text-xs text-base-content/60 space-y-1">
              <p>Ο κωδικός πρέπει να περιέχει:</p>
              <ul class="list-disc list-inside">
                <li>Τουλάχιστον 8 χαρακτήρες</li>
                <li>Ένα κεφαλαίο γράμμα</li>
                <li>Ένα πεζό γράμμα</li>
                <li>Έναν αριθμό</li>
              </ul>
            </div>
          </div>

          <input type="hidden" name="user[role]" value={@role} />

          <div>
            <.button type="submit" class="w-full btn-primary" phx-disable-with="Δημιουργία...">
              <.icon name="hero-check" class="w-5 h-5 mr-2" />
              Δημιουργία Λογαριασμού
            </.button>
          </div>
        </.form>

        <div class="text-center">
          <p class="text-base-content/70">
            Έχετε ήδη λογαριασμό;
            <.link navigate={~p"/login"} class="link link-primary">
              Σύνδεση
            </.link>
          </p>
        </div>

        <%= if @role == "patient" do %>
          <div class="text-center">
            <.link navigate={~p"/register/doctor"} class="link text-sm">
              Είστε γιατρός; Εγγραφείτε εδώ →
            </.link>
          </div>
        <% else %>
          <div class="text-center">
            <.link navigate={~p"/register"} class="link text-sm">
              ← Εγγραφή ως ασθενής
            </.link>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(params, _session, socket) do
    role = if params["role"] == "doctor", do: "doctor", else: "patient"
    changeset = Accounts.change_user_registration(%User{}, %{"role" => role})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false, role: role)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_params(params, _url, socket) do
    role = if params["role"] == "doctor", do: "doctor", else: "patient"
    {:noreply, assign(socket, role: role)}
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
