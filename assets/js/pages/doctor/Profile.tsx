import { Button, Card, Group, MultiSelect, NumberInput, Stack, Switch, Text, Textarea, TextInput, Title } from '@mantine/core'
import { useForm } from '@mantine/form'
import { router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

type Profile = {
  id: string
  first_name: string
  last_name: string
  title: string | null
  pronouns: string | null
  academic_title: string | null
  hospital_affiliation: string | null
  registration_number: string | null
  years_of_experience: number | null
  specialty_id: string | null
  bio: string | null
  bio_el: string | null
  address: string | null
  city: string | null
  telemedicine_available: boolean
  consultation_fee: number | null
  board_certifications: string[]
  languages: string[]
  insurance_networks: string[]
  sub_specialties: string[]
  clinical_procedures: string[]
  conditions_treated: string[]
}

type PageProps = AppPageProps<{
  doctor: Profile
  specialties: { id: string; name: string }[]
  errors?: Record<string, string[]>
}>

const DoctorProfilePage = ({ app, auth, doctor, specialties, errors }: PageProps) => {
  const { t } = useTranslation('default')

  const form = useForm<Profile>({
    initialValues: doctor
  })

  const handleSubmit = (values: Profile) => {
    router.post('/dashboard/doctor/profile', { doctor: values }, { preserveScroll: true })
  }

  return (
    <PublicLayout app={app} auth={auth}>
      <Stack gap="xl">
        <div>
          <Title order={2}>{t('doctor.profile.title', 'Edit profile')}</Title>
          <Text c="dimmed">{t('doctor.profile.subtitle', 'Complete your information to appear in search')}</Text>
        </div>

        <form onSubmit={form.onSubmit(handleSubmit)} className="space-y-24">
          <Card withBorder padding="xl" radius="lg">
            <Stack gap="md">
              <Title order={4}>{t('doctor.profile.basic', 'Basic info')}</Title>
              <Group grow>
                <TextInput label={t('doctor.profile.first_name', 'First name')} {...form.getInputProps('first_name')} required />
                <TextInput label={t('doctor.profile.last_name', 'Last name')} {...form.getInputProps('last_name')} required />
              </Group>
              <Group grow>
                <TextInput label={t('doctor.profile.title_field', 'Title')} {...form.getInputProps('title')} />
                <TextInput label={t('doctor.profile.academic_title', 'Academic title')} {...form.getInputProps('academic_title')} />
              </Group>
              <Group grow>
                <TextInput label={t('doctor.profile.registration_number', 'Registration number')} {...form.getInputProps('registration_number')} />
                <NumberInput label={t('doctor.profile.experience', 'Years of experience')} {...form.getInputProps('years_of_experience')} min={0} />
              </Group>
              <TextInput label={t('doctor.profile.hospital', 'Hospital affiliation')} {...form.getInputProps('hospital_affiliation')} />
              <TextInput
                label={t('doctor.profile.specialty', 'Specialty')}
                component="select"
                {...form.getInputProps('specialty_id')}
              >
                <option value="">{t('doctor.profile.select_specialty', 'Select specialty')}</option>
                {specialties.map((opt) => (
                  <option key={opt.id} value={opt.id}>
                    {opt.name}
                  </option>
                ))}
              </TextInput>
              <Textarea label={t('doctor.profile.bio_en', 'Bio (EN)')} autosize minRows={4} {...form.getInputProps('bio')} />
              <Textarea label={t('doctor.profile.bio_el', 'Bio (EL)')} autosize minRows={4} {...form.getInputProps('bio_el')} />
            </Stack>
          </Card>

          <Card withBorder padding="xl" radius="lg">
            <Stack gap="md">
              <Title order={4}>{t('doctor.profile.professional', 'Professional')}</Title>
              <TagInput label={t('doctor.profile.certifications', 'Certifications')} {...form.getInputProps('board_certifications')} />
              <TagInput label={t('doctor.profile.languages', 'Languages')} {...form.getInputProps('languages')} />
              <TagInput label={t('doctor.profile.insurance', 'Insurance networks')} {...form.getInputProps('insurance_networks')} />
            </Stack>
          </Card>

          <Card withBorder padding="xl" radius="lg">
            <Stack gap="md">
              <Title order={4}>{t('doctor.profile.location', 'Location & services')}</Title>
              <Group grow>
                <TextInput label={t('doctor.profile.address', 'Address')} {...form.getInputProps('address')} />
                <TextInput label={t('doctor.profile.city', 'City')} {...form.getInputProps('city')} />
              </Group>
              <Switch label={t('doctor.profile.telemedicine', 'Telemedicine available')} {...form.getInputProps('telemedicine_available', { type: 'checkbox' })} />
              <NumberInput label={t('doctor.profile.fee', 'Consultation fee (€)')} {...form.getInputProps('consultation_fee')} min={0} step={5} />
            </Stack>
          </Card>

          <Card withBorder padding="xl" radius="lg">
            <Stack gap="md">
              <Title order={4}>{t('doctor.profile.expertise', 'Expertise')}</Title>
              <TagInput label={t('doctor.profile.sub_specialties', 'Sub-specialties')} {...form.getInputProps('sub_specialties')} />
              <TagInput label={t('doctor.profile.procedures', 'Clinical procedures')} {...form.getInputProps('clinical_procedures')} />
              <TagInput label={t('doctor.profile.conditions', 'Conditions treated')} {...form.getInputProps('conditions_treated')} />
            </Stack>
          </Card>

          <Group justify="flex-end">
            <Button type="submit">{t('doctor.profile.save', 'Save')}</Button>
          </Group>
        </form>
      </Stack>
    </PublicLayout>
  )
}

const TagInput = ({ label, value, onChange }: { label: string; value: string[]; onChange: (value: string[]) => void }) => (
  <MultiSelect
    label={label}
    data={value}
    searchable
    creatable
    getCreateLabel={(query) => `+ ${query}`}
    onCreate={(query) => {
      const item = query.trim()
      onChange([...value, item])
      return item
    }}
    value={value}
    onChange={onChange}
  />
)

export default DoctorProfilePage
