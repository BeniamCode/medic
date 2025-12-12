import {
  Badge,
  Button,
  Card,
  Divider,
  Group,
  MultiSelect,
  NumberInput,
  Paper,
  Progress,
  Stack,
  Switch,
  Text,
  Textarea,
  TextInput,
  ThemeIcon,
  Title
} from '@mantine/core'
import { useForm } from '@mantine/form'
import { router } from '@inertiajs/react'
import { useEffect } from 'react'
import { useTranslation } from 'react-i18next'

import type { AppPageProps } from '@/types/app'
import { IconCheck, IconClipboardText, IconMapPin } from '@tabler/icons-react'

const LANGUAGE_OPTIONS = ['Ελληνικά', 'English', 'Deutsch', 'Français', 'Italiano', 'Türkçe', 'Русский']
const INSURANCE_OPTIONS = ['ΕΟΠΥΥ', 'Interamerican', 'Eurolife', 'Ethniki', 'Generali', 'Other']
const CERTIFICATION_HINTS = ['European Board Certification', 'Greek Medical Association', 'American Board Certification']
const SUB_SPECIALTY_OPTIONS = ['Cardiology', 'Dermatology', 'Orthopedics', 'Endocrinology', 'Neurology']
const PROCEDURE_OPTIONS = ['MRI Consultation', 'Endoscopy', 'Physical Therapy Eval', 'Telemedicine Follow-up']
const CONDITION_OPTIONS = ['Hypertension', 'Diabetes', 'Back Pain', 'Anxiety', 'Skin Allergy']

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

  const normalizedDoctor = normalizeDoctor(doctor)

  const form = useForm<Profile>({
    initialValues: normalizedDoctor
  })

  useEffect(() => {
    form.setValues(normalizeDoctor(doctor))
  }, [doctor])

  const handleSubmit = (values: Profile) => {
    router.post('/dashboard/doctor/profile', { doctor: values }, { preserveScroll: true })
  }

  const completion = calculateCompletion(doctor)

  return (
    <Stack gap="xl" p="xl">
          <Paper radius="lg" p="xl" withBorder className="bg-gradient-to-r from-sky-50 to-teal-50">
            <Group justify="space-between" align="flex-start" gap="xl" wrap="wrap">
              <div>
                <Title order={2}>{t('doctor.profile.title', 'Doctor profile')}</Title>
                <Text c="dimmed" maw={520} mt="sm">
                  {t(
                    'doctor.profile.subtitle',
                    'Polish your public profile so patients instantly understand who you are, what you treat, and how to book you.'
                  )}
                </Text>
                <Group gap="xs" mt="md">
                  <Badge variant="filled" color="teal">
                    {t('doctor.profile.badge_verified', 'Visible in search')}
                  </Badge>
                  <Badge variant="light" color="blue">
                    {t('doctor.profile.badge_secure', 'Secure data')}
                  </Badge>
                </Group>
              </div>

              <Stack gap="xs" className="min-w-[220px]">
                <Group justify="space-between" gap="xs">
                  <Text size="sm" fw={600}>
                    {t('doctor.profile.completeness', 'Profile completeness')}
                  </Text>
                  <Text size="sm" c="dimmed">
                    {completion}%
                  </Text>
                </Group>
                <Progress radius="xl" value={completion} color="teal" size="lg" striped animated>
                  <Progress.Section value={completion} color="teal" />
                </Progress>
                <Group gap="xs">
                  <ThemeIcon size="sm" radius="xl" color="teal" variant="light">
                    <IconClipboardText size={14} />
                  </ThemeIcon>
                  <Text size="sm" c="dimmed">
                    {t('doctor.profile.helptext', 'Complete all sections to unlock premium placements.')}
                  </Text>
                </Group>
              </Stack>
            </Group>
          </Paper>

          <Paper radius="lg" p="xl" withBorder>
            <Stack gap="md">
              <Group gap="sm" align="center">
                <ThemeIcon size="lg" radius="xl" color="teal" variant="light">
                  <IconMapPin size={18} />
                </ThemeIcon>
                <div>
                  <Text fw={600}>{t('doctor.profile.quick_actions', 'Quick actions')}</Text>
                  <Text size="sm" c="dimmed">
                    {t('doctor.profile.quick_actions_desc', 'Update your public card in one place and preview the patient-facing layout.')}
                  </Text>
                </div>
              </Group>
              <Divider my="xs" />
              <Group gap="md" wrap="wrap">
                {['basic', 'professional', 'location', 'expertise'].map((section) => (
                  <Button
                    key={section}
                    variant="light"
                    size="sm"
                    color="teal"
                    radius="xl"
                    leftSection={<IconCheck size={16} />}
                    component="a"
                    href={`#${section}`}
                  >
                    {t(`doctor.profile.jump_${section}`, section)}
                  </Button>
                ))}
              </Group>
            </Stack>
          </Paper>

        <form onSubmit={form.onSubmit(handleSubmit)} className="space-y-24">
          <Card withBorder padding="xl" radius="lg">
            <Stack gap="md" id="basic">
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
            <Stack gap="md" id="professional">
              <Title order={4}>{t('doctor.profile.professional', 'Professional')}</Title>
              <TagInput
                label={t('doctor.profile.certifications', 'Certifications')}
                value={form.values.board_certifications}
                onChange={(val) => form.setFieldValue('board_certifications', val)}
                options={CERTIFICATION_HINTS}
                placeholder={t('doctor.profile.certifications_placeholder', 'e.g. European Board of ...')}
              />
              <TagInput
                label={t('doctor.profile.languages', 'Languages')}
                value={form.values.languages}
                onChange={(val) => form.setFieldValue('languages', val)}
                options={LANGUAGE_OPTIONS}
                placeholder={t('doctor.profile.languages_placeholder', 'Select or add languages')}
              />
              <TagInput
                label={t('doctor.profile.insurance', 'Insurance networks')}
                value={form.values.insurance_networks}
                onChange={(val) => form.setFieldValue('insurance_networks', val)}
                options={INSURANCE_OPTIONS}
                placeholder={t('doctor.profile.insurance_placeholder', 'Choose accepted networks')}
              />
            </Stack>
          </Card>

          <Card withBorder padding="xl" radius="lg">
            <Stack gap="md" id="location">
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
            <Stack gap="md" id="expertise">
              <Title order={4}>{t('doctor.profile.expertise', 'Expertise')}</Title>
              <TagInput
                label={t('doctor.profile.sub_specialties', 'Sub-specialties')}
                value={form.values.sub_specialties}
                onChange={(val) => form.setFieldValue('sub_specialties', val)}
                options={SUB_SPECIALTY_OPTIONS}
                placeholder={t('doctor.profile.sub_specialties_placeholder', 'Add focus areas')}
              />
              <TagInput
                label={t('doctor.profile.procedures', 'Clinical procedures')}
                value={form.values.clinical_procedures}
                onChange={(val) => form.setFieldValue('clinical_procedures', val)}
                options={PROCEDURE_OPTIONS}
              />
              <TagInput
                label={t('doctor.profile.conditions', 'Conditions treated')}
                value={form.values.conditions_treated}
                onChange={(val) => form.setFieldValue('conditions_treated', val)}
                options={CONDITION_OPTIONS}
              />
            </Stack>
          </Card>

          <Group justify="flex-end">
            <Button type="submit">{t('doctor.profile.save', 'Save')}</Button>
          </Group>
        </form>
      </Stack>
  )
}

const TagInput = ({
  label,
  value,
  onChange,
  options = [],
  placeholder
}: {
  label: string
  value: string[]
  onChange: (value: string[]) => void
  options?: string[]
  placeholder?: string
}) => {
  const data = Array.from(new Set([...(options || []), ...(value || [])])).map((option) => ({
    value: option,
    label: option
  }))

  return (
    <MultiSelect
      label={label}
      data={data}
      searchable
      creatable
      placeholder={placeholder}
      value={value || []}
      onChange={onChange}
      getCreateLabel={(query) => `+ ${query}`}
      onCreate={(query) => {
        const item = query.trim()
        if (!item) return item
        const next = [...(value || []), item]
        onChange(next)
        return item
      }}
      nothingFound={placeholder || 'Add a new entry'}
    />
  )
}

export default DoctorProfilePage

const calculateCompletion = (doctor: Profile) => {
  const requiredKeys: (keyof Profile)[] = ['first_name', 'last_name', 'bio', 'specialty_id', 'city']
  const filled = requiredKeys.filter((key) => {
    const value = doctor[key]
    return Array.isArray(value) ? value.length > 0 : Boolean(value)
  }).length

  return Math.min(100, Math.round((filled / requiredKeys.length) * 100)) || 20
}

const normalizeDoctor = (doctor: Profile): Profile => ({
  ...doctor,
  first_name: doctor.first_name || '',
  last_name: doctor.last_name || '',
  title: doctor.title || '',
  pronouns: doctor.pronouns || '',
  academic_title: doctor.academic_title || '',
  hospital_affiliation: doctor.hospital_affiliation || '',
  registration_number: doctor.registration_number || '',
  years_of_experience: doctor.years_of_experience ?? null,
  specialty_id: doctor.specialty_id || '',
  bio: doctor.bio || '',
  bio_el: doctor.bio_el || '',
  address: doctor.address || '',
  city: doctor.city || '',
  telemedicine_available: doctor.telemedicine_available ?? false,
  consultation_fee: doctor.consultation_fee ?? null,
  board_certifications: doctor.board_certifications || [],
  languages: doctor.languages || [],
  insurance_networks: doctor.insurance_networks || [],
  sub_specialties: doctor.sub_specialties || [],
  clinical_procedures: doctor.clinical_procedures || [],
  conditions_treated: doctor.conditions_treated || []
})
