import { Button, Card, Group, NumberInput, Progress, Radio, Select, Stack, Switch, Text, Textarea, TextInput, Title } from '@mantine/core'
import { IconArrowLeft, IconArrowRight } from '@tabler/icons-react'
import { useForm } from '@mantine/form'
import { router } from '@inertiajs/react'
import { useMemo } from 'react'
import { useTranslation } from 'react-i18next'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

const STEPS_ORDER = ['welcome', 'personal', 'specialty', 'location', 'pricing', 'complete'] as const

type Step = (typeof STEPS_ORDER)[number]

type DoctorForm = {
  title?: string | null
  first_name?: string | null
  last_name?: string | null
  registration_number?: string | null
  years_of_experience?: number | null
  specialty_id?: string | null
  bio?: string | null
  city?: string | null
  address?: string | null
  telemedicine_available: boolean
  consultation_fee?: number | null
}

type PageProps = AppPageProps<{
  step: string
  steps: string[]
  doctor: DoctorForm
  specialties: { id: string; name: string }[]
  errors?: Record<string, string[]>
}>

const DoctorOnboardingPage = ({ app, auth, step, steps, doctor, specialties }: PageProps) => {
  const { t } = useTranslation('default')
  const form = useForm<DoctorForm>({ initialValues: doctor })

  const currentStep = useMemo<Step>(() => (steps.includes(step) ? (step as Step) : 'welcome'), [step, steps])

  const stepIndex = steps.indexOf(currentStep)
  const progress = Math.min(((stepIndex || 0) / (steps.length - 1)) * 100, 100)

  const nextStep = () => {
    router.post(`/onboarding/doctor?step=${currentStep}`, { doctor: form.values })
  }

  const prevStep = () => {
    const idx = STEPS_ORDER.indexOf(currentStep)
    const prev = STEPS_ORDER[Math.max(0, idx - 1)]
    router.get(`/onboarding/doctor?step=${prev}`)
  }

  const isComplete = currentStep === 'complete'

  return (
    <PublicLayout app={app} auth={auth}>
      <Stack gap="xl" maw={640} mx="auto">
        <Stack gap={4}>
          <Text size="sm" c="dimmed">
            {t('onboarding.progress', 'Step {{step}} of {{total}}', { step: stepIndex, total: steps.length - 1 })}
          </Text>
          <Progress value={progress} color="teal" radius="lg" size="lg" />
        </Stack>

        <Card padding="xl" radius="lg" shadow="xl">
          {renderStep(currentStep, form, specialties, t)}
        </Card>

        {!isComplete && (
          <Group justify="space-between">
            {currentStep !== 'welcome' ? (
              <Button variant="subtle" leftSection={<IconArrowLeft size={16} />} onClick={prevStep}>
                {t('onboarding.back', 'Back')}
              </Button>
            ) : (
              <div />
            )}
            <Button rightSection={<IconArrowRight size={16} />} onClick={nextStep}>
              {currentStep === 'pricing'
                ? t('onboarding.finish', 'Complete setup')
                : t('onboarding.next', 'Continue')}
            </Button>
          </Group>
        )}
      </Stack>
    </PublicLayout>
  )
}

const renderStep = (
  step: Step,
  form: ReturnType<typeof useForm<DoctorForm>>,
  specialties: { id: string; name: string }[],
  t: ReturnType<typeof useTranslation>['t']
) => {
  switch (step) {
    case 'welcome':
      return (
        <Stack gap="md" ta="center">
          <Title order={2}>{t('onboarding.welcome.title', 'Welcome to Medic')}</Title>
          <Text c="dimmed">{t('onboarding.welcome.body', 'Let’s set up your profile in a few quick steps.')}</Text>
        </Stack>
      )
    case 'personal':
      return (
        <Stack gap="md">
          <Title order={3}>{t('onboarding.personal.title', 'Tell us about you')}</Title>
          <Group grow>
            <TextInput label={t('onboarding.personal.title_label', 'Title')} {...form.getInputProps('title')} />
            <TextInput label={t('onboarding.personal.first_name', 'First name')} required {...form.getInputProps('first_name')} />
          </Group>
          <TextInput label={t('onboarding.personal.last_name', 'Last name')} required {...form.getInputProps('last_name')} />
          <Group grow>
            <TextInput
              label={t('onboarding.personal.registration', 'Registration number')}
              {...form.getInputProps('registration_number')}
            />
            <NumberInput
              label={t('onboarding.personal.experience', 'Years of experience')}
              min={0}
              {...form.getInputProps('years_of_experience')}
            />
          </Group>
        </Stack>
      )
    case 'specialty':
      return (
        <Stack gap="md">
          <Title order={3}>{t('onboarding.specialty.title', 'Specialty')}</Title>
          <Select
            data={specialties.map((s) => ({ value: s.id, label: s.name }))}
            label={t('onboarding.specialty.select', 'Choose your specialty')}
            placeholder={t('onboarding.specialty.placeholder', 'Select specialty')}
            {...form.getInputProps('specialty_id')}
          />
          <Textarea
            label={t('onboarding.specialty.bio', 'Bio (optional)')}
            autosize
            minRows={4}
            {...form.getInputProps('bio')}
          />
        </Stack>
      )
    case 'location':
      return (
        <Stack gap="md">
          <Title order={3}>{t('onboarding.location.title', 'Location')}</Title>
          <Group grow>
            <TextInput label={t('onboarding.location.city', 'City')} {...form.getInputProps('city')} />
            <TextInput label={t('onboarding.location.address', 'Address')} {...form.getInputProps('address')} />
          </Group>
          <Switch
            label={t('onboarding.location.telemed', 'I offer telemedicine appointments')}
            {...form.getInputProps('telemedicine_available', { type: 'checkbox' })}
          />
        </Stack>
      )
    case 'pricing':
      return (
        <Stack gap="md">
          <Title order={3}>{t('onboarding.pricing.title', 'Consultation fee')}</Title>
          <NumberInput
            label={t('onboarding.pricing.fee', 'Fee (€)')}
            min={0}
            step={5}
            {...form.getInputProps('consultation_fee')}
          />
        </Stack>
      )
    case 'complete':
      return (
        <Stack gap="md" ta="center">
          <Title order={2}>{t('onboarding.complete.title', 'All done!')}</Title>
          <Text c="dimmed">{t('onboarding.complete.body', 'Your profile is ready. Set your availability next.')}</Text>
          <Button component="a" href="/doctor/schedule">
            {t('onboarding.complete.cta', 'Set availability')}
          </Button>
        </Stack>
      )
    default:
      return null
  }
}

export default DoctorOnboardingPage
