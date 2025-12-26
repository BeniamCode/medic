defmodule Medic.Notifications.EmailLog do
  use Ash.Resource,
    domain: Medic.Notifications,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "email_logs"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      primary? true
      accept [:to, :subject, :template_name, :status, :error, :triggered_by, :html_body]
      argument :user_id, :uuid

      change manage_relationship(:user_id, :user, type: :append)
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :to, :string do
      allow_nil? false
    end

    attribute :subject, :string do
      allow_nil? false
    end

    attribute :template_name, :string do
      allow_nil? true
    end

    attribute :status, :atom do
      constraints [one_of: [:sent, :failed]]
      allow_nil? false
      default :sent
    end

    attribute :error, :string do
      allow_nil? true
    end

    attribute :triggered_by, :string do
      allow_nil? true
    end

    attribute :html_body, :string do
      allow_nil? true
    end

    timestamps()
  end

  relationships do
    belongs_to :user, Medic.Accounts.User do
      domain Medic.Accounts
      allow_nil? true
    end
  end
end
