defmodule Medic.NotificationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Medic.Notifications` context.
  """

  @doc """
  Generate a notification.
  """
  def notification_fixture(attrs \\ %{}) do
    {:ok, user} =
      Medic.Accounts.register_user(%{
        email: "user_#{System.unique_integer()}@example.com",
        password: "Password123!",
        role: "patient"
      })

    {:ok, notification} =
      attrs
      |> Enum.into(%{
        message: "some message",
        read_at: ~U[2025-12-06 17:26:00Z],
        resource_id: "some resource_id",
        resource_type: "some resource_type",
        title: "some title",
        type: "some type",
        user_id: user.id
      })
      |> Medic.Notifications.create_notification()

    notification
  end
end
