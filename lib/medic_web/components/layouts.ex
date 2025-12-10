defmodule MedicWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use MedicWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  # The app layout is defined in layouts/app.html.heex

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  def user_display_name(nil), do: nil

  def user_display_name(%{doctor: %{first_name: first, last_name: last}})
      when not is_nil(first) do
    "Dr. #{first} #{last}"
  end

  def user_display_name(%{patient: %{first_name: first, last_name: last}})
      when not is_nil(first) do
    "#{first} #{last}"
  end

  def user_display_name(%{email: email}) do
    email
  end

  attr :unread, :integer, default: 0

  def notification_bell(assigns) do
    ~H"""
    <a href="/notifications" class="btn btn-ghost btn-circle">
      <div class="indicator">
        <.icon name="hero-bell" class="size-5" />
        <%= if @unread > 0 do %>
          <span class="badge badge-primary badge-xs indicator-item">
            <%= if @unread > 9, do: "9+", else: @unread %>
          </span>
        <% end %>
      </div>
    </a>
    """
  end

  def nav_link_class(assigns, view_pattern, path, opts \\ []) do
    match_type = Keyword.get(opts, :match, :exact)

    active =
      cond do
        assigns[:socket] ->
          String.contains?(to_string(assigns[:socket].view), view_pattern)

        assigns[:conn] ->
          current_path = assigns[:conn].request_path

          if match_type == :prefix do
            String.starts_with?(current_path, path)
          else
            current_path == path
          end

        true ->
          false
      end

    if active, do: "active"
  end
end
