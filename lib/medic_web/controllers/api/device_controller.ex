defmodule MedicWeb.API.DeviceController do
  @moduledoc """
  Device API controller for mobile app.
  Handles push notification device registration.
  
  Note: This is a stub implementation. You'll need to create a DeviceToken
  resource in your Notifications domain to store device tokens.
  """
  use MedicWeb, :controller

  action_fallback MedicWeb.API.FallbackController

  @doc """
  POST /api/devices
  Register a device for push notifications.
  """
  def create(conn, params) do
    user = conn.assigns.current_user
    
    # TODO: Implement when DeviceToken resource is created
    # For now, return success as a stub
    token = params["token"]
    platform = params["platform"] || "ios"
    
    if is_nil(token) do
      conn
      |> put_status(:bad_request)
      |> json(%{error: "Token is required"})
    else
      # Store token (implement your storage logic)
      # Example: Notifications.register_device(%{user_id: user.id, token: token, platform: platform})
      
      conn
      |> put_status(:created)
      |> json(%{data: %{token: token, platform: platform, user_id: user.id}})
    end
  end

  @doc """
  DELETE /api/devices/:token
  Unregister a device.
  """
  def delete(conn, %{"token" => token}) do
    _user = conn.assigns.current_user
    
    # TODO: Remove token when DeviceToken resource is created
    # Example: Notifications.unregister_device(user.id, token)
    
    conn
    |> put_status(:ok)
    |> json(%{success: true, message: "Device unregistered"})
  end
end
