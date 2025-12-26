defmodule Medic.Notifications.EmailTemplate do
  use Ash.Resource,
    domain: Medic.Notifications,
    data_layer: AshPostgres.DataLayer

  postgres do
    table "email_templates"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :create, :update, :destroy]

    read :by_name do
      argument :name, :string, allow_nil?: false
      filter expr(name == ^arg(:name))
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :string do
      allow_nil? false
      constraints [min_length: 1]
    end

    attribute :subject, :string do
      allow_nil? false
    end

    attribute :html_body, :string do
      allow_nil? false
    end

    attribute :text_body, :string do
      allow_nil? true
    end

    attribute :sender_name, :string do
      allow_nil? false
      default "Medic"
    end

    attribute :sender_address, :string do
      allow_nil? false
      default "hi@medic.gr"
    end

    attribute :description, :string do
      allow_nil? true
    end

    attribute :variables, :map do
      allow_nil? true
      default %{}
    end

    timestamps()
  end

  identities do
    identity :unique_name, [:name]
  end
end
