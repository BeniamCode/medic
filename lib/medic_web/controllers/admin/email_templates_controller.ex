defmodule MedicWeb.Admin.EmailTemplatesController do
  use MedicWeb, :controller

  alias Medic.Notifications

  def index(conn, _params) do
    templates = Notifications.list_email_templates()
    render_inertia(conn, "Admin/EmailTemplates/Index", %{templates: templates})
  end

  def new(conn, _params) do
    render_inertia(conn, "Admin/EmailTemplates/Form", %{template: nil})
  end

  def create(conn, params) do
    case Notifications.create_email_template(params) do
      {:ok, _template} ->
        conn
        |> put_flash(:info, "Template created successfully.")
        |> redirect(to: ~p"/medic/email_templates")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Could not create template.")
        |> render_inertia("Admin/EmailTemplates/Form", %{template: nil, errors: format_errors(changeset)})
    end
  end

  def edit(conn, %{"id" => id}) do
    template = Notifications.get_email_template!(id)
    render_inertia(conn, "Admin/EmailTemplates/Form", %{template: template})
  end

  def update(conn, %{"id" => id} = params) do
    template = Notifications.get_email_template!(id)

    case Notifications.update_email_template(template, params) do
      {:ok, _template} ->
        conn
        |> put_flash(:info, "Template updated successfully.")
        |> redirect(to: ~p"/medic/email_templates")

      {:error, changeset} ->
        conn
        |> put_flash(:error, "Could not update template.")
        |> render_inertia("Admin/EmailTemplates/Form", %{template: template, errors: format_errors(changeset)})
    end
  end

  def delete(conn, %{"id" => id}) do
    template = Notifications.get_email_template!(id)

    case Notifications.delete_email_template(template) do
      :ok ->
        conn
        |> put_flash(:info, "Template deleted successfully.")
        |> redirect(to: ~p"/medic/email_templates")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Could not delete template.")
        |> redirect(to: ~p"/medic/email_templates")
    end
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
