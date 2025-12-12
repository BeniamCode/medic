defmodule Medic.NotificationsTest do
  use Medic.DataCase

  alias Medic.Notifications
  alias Ash.Error.Invalid

  describe "notifications" do
    alias Medic.Notifications.Notification

    import Medic.NotificationsFixtures

    @invalid_attrs %{
      message: nil,
      type: nil,
      title: nil,
      read_at: nil,
      resource_id: nil,
      resource_type: nil
    }

    test "list_notifications/0 returns all notifications" do
      notification = notification_fixture()
      assert Enum.map(Notifications.list_notifications(), & &1.id) == [notification.id]
    end

    test "get_notification!/1 returns the notification with given id" do
      notification = notification_fixture()
      assert Notifications.get_notification!(notification.id).id == notification.id
    end

    test "create_notification/1 with valid data creates a notification" do
      {:ok, user} =
        Medic.Accounts.register_user(%{
          email: "user_#{System.unique_integer()}@example.com",
          password: "Password123!",
          role: "patient"
        })

      valid_attrs = %{
        message: "some message",
        type: "some type",
        title: "some title",
        read_at: ~U[2025-12-06 17:26:00Z],
        resource_id: "some resource_id",
        resource_type: "some resource_type",
        user_id: user.id
      }

      assert {:ok, %Notification{} = notification} =
               Notifications.create_notification(valid_attrs)

      assert notification.message == "some message"
      assert notification.type == "some type"
      assert notification.title == "some title"
      assert notification.read_at == ~U[2025-12-06 17:26:00Z]
      assert notification.resource_id == "some resource_id"
      assert notification.resource_type == "some resource_type"
    end

    test "create_notification/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notifications.create_notification(@invalid_attrs)
    end

    test "update_notification/2 with valid data updates the notification" do
      notification = notification_fixture()

      update_attrs = %{
        message: "some updated message",
        type: "some updated type",
        title: "some updated title",
        read_at: ~U[2025-12-07 17:26:00Z],
        resource_id: "some updated resource_id",
        resource_type: "some updated resource_type"
      }

      assert {:ok, %Notification{} = notification} =
               Notifications.update_notification(notification, update_attrs)

      assert notification.message == "some updated message"
      assert notification.type == "some updated type"
      assert notification.title == "some updated title"
      assert notification.read_at == ~U[2025-12-07 17:26:00Z]
      assert notification.resource_id == "some updated resource_id"
      assert notification.resource_type == "some updated resource_type"
    end

    test "update_notification/2 with invalid data returns error changeset" do
      notification = notification_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_notification(notification, @invalid_attrs)

      assert notification.id == Notifications.get_notification!(notification.id).id
    end

    test "delete_notification/1 deletes the notification" do
      notification = notification_fixture()
      assert {:ok, %Notification{}} = Notifications.delete_notification(notification)
      assert_raise Invalid, fn -> Notifications.get_notification!(notification.id) end
    end

    test "change_notification/1 returns a notification changeset" do
      notification = notification_fixture()
      assert %Ecto.Changeset{} = Notifications.change_notification(notification)
    end
  end
end
