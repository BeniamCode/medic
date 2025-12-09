defmodule Medic.Doctors.Specialty do
  @moduledoc """
  Medical specialty schema with bilingual support (English/Greek).
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "specialties" do
    field :name_en, :string
    field :name_el, :string
    field :slug, :string
    field :icon, :string

    has_many :doctors, Medic.Doctors.Doctor

    timestamps(type: :utc_datetime)
  end

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

  @doc """
  Returns the localized name based on the given locale.
  """
  def localized_name(%__MODULE__{} = specialty, locale) when locale in ["el", :el] do
    specialty.name_el
  end

  def localized_name(%__MODULE__{} = specialty, _locale) do
    specialty.name_en
  end
end
