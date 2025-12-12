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
import { router } from '@inertiajs/react'
import { useMutation } from '@tanstack/react-query'
import { Controller, useForm } from 'react-hook-form'
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

const DoctorProfilePage = ({ doctor, specialties }: PageProps) => {
  const { t } = useTranslation('default')
  const normalizedDoctor = normalizeDoctor(doctor)

  const {
    control,
    register,
    handleSubmit,
    reset,
    formState: { errors: formErrors }
  } = useForm<Profile>({
    defaultValues: normalizedDoctor
  })

  useEffect(() => {
    reset(normalizedDoctor)
  }, [normalizedDoctor, reset])

  const mutation = useMutation({
    mutationFn: async (values: Profile) =>
      await new Promise<void>((resolve, reject) => {
        router.post('/dashboard/doctor/profile', { doctor: values }, {
          preserveScroll: true,
          onSuccess: () => resolve(),
          onError: () => reject(new Error('Failed to save doctor profile'))
        })
      })
  })

  const onSubmit = (values: Profile) => mutation.mutate(values)

  const completion = calculateCompletion(normalizedDoctor)

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

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-24">
        <Card withBorder padding="xl" radius="lg">
          <Stack gap="md" id="basic">
            <Title order={4}>{t('doctor.profile.basic', 'Basic info')}</Title>
            <Group grow>
              <TextInput
                label={t('doctor.profile.first_name', 'First name')}
                required
                {...register('first_name', { required: true })}
                error={formErrors.first_name?.message}
              />
              <TextInput
                label={t('doctor.profile.last_name', 'Last name')}
                required
                {...register('last_name', { required: true })}
                error={formErrors.last_name?.message}
              />
            </Group>
            <Group grow>
              <TextInput label={t('doctor.profile.title_field', 'Title')} {...register('title')} />
              <TextInput label={t('doctor.profile.academic_title', 'Academic title')} {...register('academic_title')} />
            </Group>
            <Group grow>
              <TextInput label={t('doctor.profile.registration_number', 'Registration number')} {...register('registration_number')} />
              <Controller
                control={control}
                name="years_of_experience"
                render={({ field }) => (
                  <NumberInput
                    label={t('doctor.profile.experience', 'Years of experience')}
                    min={0}
                    value={field.value ?? undefined}
                    onChange={(value) => field.onChange(value === '' ? null : Number(value))}
                  />
                )}
              />
            </Group>
            <TextInput label={t('doctor.profile.hospital', 'Hospital affiliation')} {...register('hospital_affiliation')} />
            <TextInput label={t('doctor.profile.specialty', 'Specialty')} component="select" {...register('specialty_id')}>
              <option value="">{t('doctor.profile.select_specialty', 'Select specialty')}</option>
              {specialties.map((opt) => (
                <option key={opt.id} value={opt.id}>
                  {opt.name}
                </option>
              ))}
            </TextInput>
            <Textarea label={t('doctor.profile.bio_en', 'Bio (EN)')} autosize minRows={4} {...register('bio')} />
            <Textarea label={t('doctor.profile.bio_el', 'Bio (EL)')} autosize minRows={4} {...register('bio_el')} />
          </Stack>
        </Card>

        <Card withBorder padding="xl" radius="lg">
          <Stack gap="md" id="professional">
            <Title order={4}>{t('doctor.profile.professional', 'Professional')}</Title>
            <Controller
              control={control}
              name="board_certifications"
              render={({ field }) => (
                <TagInput
                  label={t('doctor.profile.certifications', 'Certifications')}
                  value={field.value || []}
                  onChange={field.onChange}
                  options={CERTIFICATION_HINTS}
                  placeholder={t('doctor.profile.certifications_placeholder', 'e.g. European Board of ...')}
                />
              )}
            />
            <Controller
              control={control}
              name="languages"
              render={({ field }) => (
                <TagInput
                  label={t('doctor.profile.languages', 'Languages')}
                  value={field.value || []}
                  onChange={field.onChange}
                  options={LANGUAGE_OPTIONS}
                  placeholder={t('doctor.profile.languages_placeholder', 'Select or add languages')}
                />
              )}
            />
            <Controller
              control={control}
              name="insurance_networks"
              render={({ field }) => (
                <TagInput
                  label={t('doctor.profile.insurance', 'Insurance networks')}
                  value={field.value || []}
                  onChange={field.onChange}
                  options={INSURANCE_OPTIONS}
                  placeholder={t('doctor.profile.insurance_placeholder', 'Choose accepted networks')}
                />
              )}
            />
          </Stack>
        </Card>

        <Card withBorder padding="xl" radius="lg">
          <Stack gap="md" id="location">
            <Title order={4}>{t('doctor.profile.location', 'Location & services')}</Title>
            <Group grow>
              <TextInput label={t('doctor.profile.address', 'Address')} {...register('address')} />
              <TextInput label={t('doctor.profile.city', 'City')} {...register('city')} />
            </Group>
            <Controller
              control={control}
              name="telemedicine_available"
              render={({ field }) => (
                <Switch
                  label={t('doctor.profile.telemedicine', 'Telemedicine available')}
                  checked={field.value}
                  onChange={(event) => field.onChange(event.currentTarget.checked)}
                />
              )}
            />
            <Controller
              control={control}
              name="consultation_fee"
              render={({ field }) => (
                <NumberInput
                  label={t('doctor.profile.fee', 'Consultation fee (€)')}
                  min={0}
                  step={5}
                  value={field.value ?? undefined}
                  onChange={(value) => field.onChange(value === '' ? null : Number(value))}
                />
              )}
            />
          </Stack>
        </Card>

        <Card withBorder padding="xl" radius="lg">
          <Stack gap="md" id="expertise">
            <Title order={4}>{t('doctor.profile.expertise', 'Expertise')}</Title>
            <Controller
              control={control}
              name="sub_specialties"
              render={({ field }) => (
                <TagInput
                  label={t('doctor.profile.sub_specialties', 'Sub-specialties')}
                  value={field.value || []}
                  onChange={field.onChange}
                  options={SUB_SPECIALTY_OPTIONS}
                  placeholder={t('doctor.profile.sub_specialties_placeholder', 'Add focus areas')}
                />
              )}
            />
            <Controller
              control={control}
              name="clinical_procedures"
              render={({ field }) => (
                <TagInput
                  label={t('doctor.profile.procedures', 'Clinical procedures')}
                  value={field.value || []}
                  onChange={field.onChange}
                  options={PROCEDURE_OPTIONS}
                />
              )}
            />
            <Controller
              control={control}
              name="conditions_treated"
              render={({ field }) => (
                <TagInput
                  label={t('doctor.profile.conditions', 'Conditions treated')}
                  value={field.value || []}
                  onChange={field.onChange}
                  options={CONDITION_OPTIONS}
                />
              )}
            />
          </Stack>
        </Card>

        <Group justify="flex-end">
          <Button type="submit" loading={mutation.isPending} disabled={mutation.isPending}>
            {t('doctor.profile.save', 'Save')}
          </Button>
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
