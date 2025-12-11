defmodule MedicWeb.UserRegistrationController do
  use MedicWeb, :controller

  alias Medic.Accounts
  alias MedicWeb.UserAuth

  def new(conn, _params) do
    conn
    |> assign(:page_title, "Register")
    |> render_inertia("Auth/Register")
  end

  def create(conn, params) do
    # Inertia sends params at top level usually, or we can look for 'user' nested 
    # depending on how useForm is set up. My React form sends top level fields.
    # But `Accounts.register_user` expects a map.
    
    # We'll construct the payload currently.
    user_params = params

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        conn
        |> put_flash(:info, "Account created successfully!")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        # For Inertia, we need to convert changeset errors to a map
        # However, standard Pheonix render_inertia might not automatically do this unless using a helper.
        # But wait, if I render Component again with errors?
        # Inertia expects 409 or similar for validation errors with errors bag.
        # But actually in Phoenix adapter, typically we pass `errors` as prop or use session errors.
        
        # Simpler approach: Put errors in flash or props.
        # The standard inertia-elixir adapter automatically puts changeset errors into props if we pass the changeset?
        # Let's try passing errors explicitly.
        
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
            opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
          end)
        end)
        # Flatten errors to {field: "error"} map since that is what Inertia client expects usually (Field -> String)
        # Traverse returns {field: ["error"]}.
        
        flat_errors = Map.new(errors, fn {k, v} -> {k, Enum.join(v, ", ")} end)

        conn
        |> assign(:errors, flat_errors) # inertia-phoenix might use this?
        |> put_status(422) # Unprocessable Entity
        |> render_inertia("Auth/Register", %{errors: flat_errors}) 
    end
  end
  def new_doctor(conn, _params) do
    conn
    |> assign(:page_title, "Doctor Registration")
    |> render_inertia("Auth/RegisterDoctor")
  end

  def create_doctor(conn, params) do
    # Force role to doctor
    doctor_params = Map.put(params, "role", "doctor")

    case Accounts.register_user(doctor_params) do
      {:ok, user} ->
        {:ok, _} =
          Accounts.deliver_user_confirmation_instructions(
            user,
            &url(~p"/users/confirm/#{&1}")
          )

        conn
        |> put_flash(:info, "Doctor account created! Please complete your profile.")
        |> put_session(:user_return_to, ~p"/onboarding/doctor")
        |> UserAuth.log_in_user(user)
        # Note: log_in_user usually halts or redirects. 
        # But UserAuth.log_in_user redirects to signed_in_path which defaults to /.
        # We need to override this behavior or handle redirection after login.
        # Actually, UserAuth.log_in_user takes optional params or we can customize.
        # Let's check UserAuth.
        
      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
          Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
            opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
          end)
        end)
        flat_errors = Map.new(errors, fn {k, v} -> {k, Enum.join(v, ", ")} end)

        conn
        |> assign(:errors, flat_errors)
        |> put_status(422)
        |> render_inertia("Auth/RegisterDoctor", %{errors: flat_errors})
    end
  end
end
