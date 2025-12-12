defmodule Medic.Doctors.Specialty do
  use Ash.Resource,
    domain: Medic.Doctors,
    data_layer: AshPostgres.DataLayer

  import Ecto.Changeset

  postgres do
    table "specialties"
    repo Medic.Repo
  end

  actions do
    defaults [:read, :destroy]

    create :create do
      primary? true
      accept [:name_en, :name_el, :slug, :icon]
    end

    update :update do
      accept [:name_en, :name_el, :slug, :icon]
    end
  end

  attributes do
    uuid_primary_key :id

    attribute :name_en, :string do
      allow_nil? false
    end

    attribute :name_el, :string do
      allow_nil? false
    end

    attribute :slug, :string do
      allow_nil? false
    end

    attribute :icon, :string

    timestamps()
  end

  relationships do
    has_many :doctors, Medic.Doctors.Doctor
  end

  calculations do
    calculate :localized_name,
              :string,
              expr(
                if ^arg(:locale) == "el" or ^arg(:locale) == :el do
                  name_el
                else
                  name_en
                end
              ) do
      argument :locale, :term, default: :en
    end
  end

  # Code interface for convenience
  code_interface do
    define :create, action: :create
    define :read_all, action: :read
    define :update, action: :update
    define :destroy, action: :destroy
    define :get_by_slug, action: :read, get_by: [:slug]
    define :get_by_id, action: :read, get_by: [:id]
  end

  # --- Legacy Logic ---

  @doc false
  def changeset(specialty, attrs) do
    specialty
    |> cast(attrs, [:name_en, :name_el, :slug, :icon])
    |> validate_required([:name_en, :name_el, :slug])
    |> unique_constraint(:slug)
    |> maybe_generate_slug()
  end

  defp maybe_generate_slug(changeset) do
    case get_change(changeset, :slug) do
      nil ->
        name = get_change(changeset, :name_en) || get_field(changeset, :name_en)

        if name do
          slug =
            name |> String.downcase() |> String.replace(~r/[^a-z0-9]+/, "-") |> String.trim("-")

          put_change(changeset, :slug, slug)
        else
          changeset
        end

      _ ->
        changeset
    end
  end
end
