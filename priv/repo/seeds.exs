# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# We recommend using the bang functions (`insert!`) as they will
# fail if something goes wrong, which is what we want here.

alias Medic.Repo
alias Medic.Doctors.Specialty

# Greek Medical Specialties
specialties = [
  %{
    name_en: "General Practitioner",
    name_el: "Γενικός Ιατρός",
    slug: "general-practitioner",
    icon: "hero-heart"
  },
  %{
    name_en: "Cardiologist",
    name_el: "Καρδιολόγος",
    slug: "cardiologist",
    icon: "hero-heart"
  },
  %{
    name_en: "Dermatologist",
    name_el: "Δερματολόγος",
    slug: "dermatologist",
    icon: "hero-hand-raised"
  },
  %{
    name_en: "Orthopedic Surgeon",
    name_el: "Ορθοπεδικός Χειρουργός",
    slug: "orthopedic-surgeon",
    icon: "hero-wrench"
  },
  %{
    name_en: "Pediatrician",
    name_el: "Παιδίατρος",
    slug: "pediatrician",
    icon: "hero-face-smile"
  },
  %{
    name_en: "Neurologist",
    name_el: "Νευρολόγος",
    slug: "neurologist",
    icon: "hero-academic-cap"
  },
  %{
    name_en: "Psychiatrist",
    name_el: "Ψυχίατρος",
    slug: "psychiatrist",
    icon: "hero-chat-bubble-left-right"
  },
  %{
    name_en: "Ophthalmologist",
    name_el: "Οφθαλμίατρος",
    slug: "ophthalmologist",
    icon: "hero-eye"
  },
  %{
    name_en: "Dentist",
    name_el: "Οδοντίατρος",
    slug: "dentist",
    icon: "hero-face-smile"
  },
  %{
    name_en: "Gynecologist",
    name_el: "Γυναικολόγος",
    slug: "gynecologist",
    icon: "hero-heart"
  },
  %{
    name_en: "Urologist",
    name_el: "Ουρολόγος",
    slug: "urologist",
    icon: "hero-beaker"
  },
  %{
    name_en: "Gastroenterologist",
    name_el: "Γαστρεντερολόγος",
    slug: "gastroenterologist",
    icon: "hero-beaker"
  },
  %{
    name_en: "Pulmonologist",
    name_el: "Πνευμονολόγος",
    slug: "pulmonologist",
    icon: "hero-cloud"
  },
  %{
    name_en: "Endocrinologist",
    name_el: "Ενδοκρινολόγος",
    slug: "endocrinologist",
    icon: "hero-beaker"
  },
  %{
    name_en: "Rheumatologist",
    name_el: "Ρευματολόγος",
    slug: "rheumatologist",
    icon: "hero-hand-raised"
  },
  %{
    name_en: "ENT Specialist",
    name_el: "Ωτορινολαρυγγολόγος",
    slug: "ent-specialist",
    icon: "hero-speaker-wave"
  },
  %{
    name_en: "Oncologist",
    name_el: "Ογκολόγος",
    slug: "oncologist",
    icon: "hero-shield-check"
  },
  %{
    name_en: "Allergist",
    name_el: "Αλλεργιολόγος",
    slug: "allergist",
    icon: "hero-shield-exclamation"
  },
  %{
    name_en: "Physiotherapist",
    name_el: "Φυσιοθεραπευτής",
    slug: "physiotherapist",
    icon: "hero-bolt"
  },
  %{
    name_en: "Psychologist",
    name_el: "Ψυχολόγος",
    slug: "psychologist",
    icon: "hero-chat-bubble-left-right"
  }
]

IO.puts("Seeding specialties...")

for specialty_attrs <- specialties do
  case Repo.get_by(Specialty, slug: specialty_attrs.slug) do
    nil ->
      %Specialty{}
      |> Specialty.changeset(specialty_attrs)
      |> Repo.insert!()
      IO.puts("  Created: #{specialty_attrs.name_en}")

    _existing ->
      IO.puts("  Exists: #{specialty_attrs.name_en}")
  end
end

IO.puts("Seeding complete!")
