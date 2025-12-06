# Production Seeds - Essential data for the application to function
# Run with: mix run priv/repo/seeds/prod.exs
# Or:       mix seed.prod

alias Medic.Repo
alias Medic.Doctors
alias Medic.Doctors.Specialty
alias Medic.MedicalTaxonomy

IO.puts("🏥 Seeding production data (specialties from taxonomy)...")

# Seed all specialties from the MedicalTaxonomy module
taxonomy_specialties = MedicalTaxonomy.specialties()

created_count =
  taxonomy_specialties
  |> Enum.map(fn spec ->
    case Doctors.get_specialty_by_slug(spec.id) do
      nil ->
        {:ok, _specialty} =
          Doctors.create_specialty(%{
            name_en: spec.name,
            name_el: spec.name_el,
            slug: spec.id,
            icon: spec.icon
          })
        :created

      _existing ->
        :exists
    end
  end)
  |> Enum.count(& &1 == :created)

total = Repo.one(from s in Specialty, select: count(s.id))

IO.puts("""

✅ Production seeding complete!

📋 Specialties: #{total} total (#{created_count} new)

  Categories include:
  - Primary Care (General Practice, Family Medicine, Internal Medicine)
  - Cardiology (Cardiology, Cardiac Surgery, Vascular Surgery)
  - Neurology (Neurology, Neurosurgery, Psychiatry)
  - And #{total - 9} more...
""")
