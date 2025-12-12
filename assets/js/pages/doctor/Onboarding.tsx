import {
  Box,
  Button,
  Center,
  Container,
  Group,
  NumberInput,
  Paper,
  Progress,
  RingProgress,
  Select,
  Stack,
  Switch,
  Text,
  Textarea,
  TextInput,
  ThemeIcon,
  Title
} from '@mantine/core'
import { useTranslation } from 'react-i18next'
import { router } from '@inertiajs/react'
import { useEffect, useMemo } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { useMutation } from '@tanstack/react-query'

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

const DoctorOnboardingPage = ({ step, steps, doctor, specialties }: PageProps) => {
  const { t } = useTranslation('default')
  const normalizedDoctor = normalizeDoctor(doctor)

  const form = useForm<DoctorForm>({
    defaultValues: normalizedDoctor
  })

  const { control, register, getValues, reset } = form

  useEffect(() => {
    reset(normalizedDoctor)
  }, [normalizedDoctor, reset])

  const currentStep = useMemo<Step>(() => (steps.includes(step) ? (step as Step) : 'welcome'), [step, steps])
  const stepIndex = STEPS_ORDER.indexOf(currentStep)
  const isComplete = currentStep === 'complete'
  const progress = Math.round((stepIndex / (STEPS_ORDER.length - 1)) * 100)

  const mutation = useMutation({
    mutationFn: async ({ values, step }: { values: DoctorForm; step: Step }) =>
      await new Promise<void>((resolve, reject) => {
        router.post(`/onboarding/doctor?step=${step}`, { doctor: values }, {
          onSuccess: () => resolve(),
          onError: () => reject(new Error('Failed to save onboarding step')),
          preserveScroll: true
        })
      })
  })

  const nextStep = () => {
    if (currentStep === 'welcome') {
      router.get('/onboarding/doctor?step=personal')
      return
    }

    mutation.mutate({ values: getValues(), step: currentStep })
  }

  const prevStep = () => {
    const idx = STEPS_ORDER.indexOf(currentStep)
    const prev = STEPS_ORDER[Math.max(0, idx - 1)]
    router.get(`/onboarding/doctor?step=${prev}`)
  }

  return (
    <Box className="min-h-screen bg-gradient-to-br from-slate-900 via-slate-800 to-slate-900 text-white">
      <Container size="lg" py="xl">
        <Stack gap="xl">
          <Group justify="space-between">
            <Group gap="xs" align="center">
              <img src="/images/logo-medic.svg" alt="Medic" className="h-8" />
              <Text fw={600} c="white">
                Medic
              </Text>
            </Group>
            <Button component="a" href="/logout" method="delete" variant="subtle" color="white" size="xs">
              {t('onboarding.sign_out', 'Sign out')}
            </Button>
          </Group>

          <Stack gap="xs">
            <Text size="sm" fw={600} tt="uppercase" opacity={0.7}>
              {t('onboarding.progress', 'Profile progress')}
            </Text>
            <Group gap="sm" align="center">
              <Progress value={progress} className="flex-1" size="lg" radius="xl" color="teal" />
              <Text fw={600}>{progress}%</Text>
            </Group>
            <Group gap="xs" wrap="wrap">
              {STEPS_ORDER.filter((s) => s !== 'complete').map((s, idx) => {
                const active = s === currentStep
                const completed = idx < stepIndex
                return (
                  <Button key={s} variant={active ? 'filled' : completed ? 'light' : 'subtle'} color="teal" size="xs" radius="xl">
                    {t(`onboarding.step.${s}`, s)}
                  </Button>
                )
              })}
            </Group>
          </Stack>

          <Center>
            <Paper radius="xl" p="xl" shadow="xl" className="bg-white text-slate-900" maw={600} w="100%">
              {renderStep(currentStep, form, specialties, t)}
            </Paper>
          </Center>

          {!isComplete && (
            <Group justify="space-between">
              {currentStep !== 'welcome' ? (
                <Button variant="subtle" leftSection={<IconArrowLeft size={18} />} onClick={prevStep}>
                  {t('onboarding.back', 'Back')}
                </Button>
              ) : (
                <div />
              )}

              <Button
                size="lg"
                radius="xl"
                rightSection={<IconArrowRight size={20} />}
                onClick={nextStep}
                loading={mutation.isPending}
                disabled={mutation.isPending}
                color="teal"
              >
                {currentStep === 'pricing'
                  ? t('onboarding.finish', 'Submit profile')
                  : currentStep === 'welcome'
                    ? t('onboarding.lets_start', "Let's start")
                    : t('onboarding.next', 'Continue')}
              </Button>
            </Group>
          )}
        </Stack>
      </Container>
    </Box>
  )
}

const renderStep = (
  step: Step,
  form: ReturnType<typeof useForm<DoctorForm>>,
  specialties: { id: string; name: string }[],
  t: ReturnType<typeof useTranslation>['t']
) => {
  const { register, control } = form

  switch (step) {
    case 'welcome':
      return (
        <Stack gap="md" align="flex-start">
          <ThemeIcon size={56} radius="xl" color="teal" variant="light">
            <IconCheck size={28} />
          </ThemeIcon>
          <Title order={1}>{t('onboarding.welcome.title', 'Welcome to Medic')}</Title>
          <Text size="lg" c="dimmed">
            {t('onboarding.welcome.copy', 'Think of this as a guided intro—answer a few friendly questions and we will shape your booking profile.')}
          </Text>
        </Stack>
      )
    case 'personal':
      return (
        <Stack gap="md">
          <Title order={2}>{t('onboarding.personal.title', 'Tell us about you')}</Title>
          <Text c="dimmed">{t('onboarding.personal.helper', 'A warm introduction helps patients know they are in excellent hands.')}</Text>
          <Group grow>
            <TextInput label={t('doctor.profile.title_field', 'Title')} placeholder="Dr." {...register('title')} />
            <TextInput label={t('doctor.profile.first_name', 'First name')} required {...register('first_name')} />
          </Group>
          <TextInput label={t('doctor.profile.last_name', 'Last name')} required {...register('last_name')} />
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
        </Stack>
      )
    case 'specialty':
      return (
        <Stack gap="md">
          <Title order={2}>{t('onboarding.specialty.title', 'What is your area of expertise?')}</Title>
          <Controller
            control={control}
            name="specialty_id"
            render={({ field }) => (
              <Select
                data={specialties.map((s) => ({ value: s.id, label: s.name }))}
                label={t('doctor.profile.specialty', 'Specialty')}
                placeholder={t('onboarding.specialty.placeholder', 'Select your specialty')}
                searchable
                value={field.value || ''}
                onChange={field.onChange}
              />
            )}
          />
          <Textarea
            label={t('doctor.profile.bio_en', 'Professional bio')}
            description={t('onboarding.specialty.helper', 'Share a short paragraph highlighting your style and focus areas.')}
            autosize
            minRows={4}
            {...register('bio')}
          />
        </Stack>
      )
    case 'location':
      return (
        <Stack gap="md">
          <Title order={2}>{t('onboarding.location.title', 'Where do you meet patients?')}</Title>
          <Group grow>
            <TextInput label={t('doctor.profile.city', 'City')} {...register('city')} />
            <TextInput label={t('doctor.profile.address', 'Street address')} {...register('address')} />
          </Group>
          <Controller
            control={control}
            name="telemedicine_available"
            render={({ field }) => (
              <Switch
                label={t('onboarding.location.telemedicine', 'Offer telemedicine appointments?')}
                checked={field.value ?? false}
                onChange={(event) => field.onChange(event.currentTarget.checked)}
              />
            )}
          />
        </Stack>
      )
    case 'pricing':
      return (
        <Stack gap="md">
          <Title order={2}>{t('onboarding.pricing.title', 'Set your consultation fee')}</Title>
          <Text c="dimmed">{t('onboarding.pricing.helper', 'Transparency builds trust—you can always fine-tune later.')}</Text>
          <Controller
            control={control}
            name="consultation_fee"
            render={({ field }) => (
              <NumberInput
                size="xl"
                leftSection={<Text fw={700}>€</Text>}
                min={0}
                step={5}
                placeholder="60"
                value={field.value ?? undefined}
                onChange={(value) => field.onChange(value === '' ? null : Number(value))}
              />
            )}
          />
        </Stack>
      )
    case 'complete':
      return (
        <Stack gap="md" align="center" ta="center">
          <RingProgress
            size={200}
            roundCaps
            thickness={18}
            sections={[{ value: 100, color: 'teal' }]}
            label={
              <Center>
                <IconCheck size={64} color="var(--mantine-color-teal-6)" />
              </Center>
            }
          />
          <Title order={1}>{t('onboarding.complete.title', 'Profile ready!')}</Title>
          <Text maw={440} c="dimmed">
            {t('onboarding.complete.helper', 'Next stop: availability. Set your calendar so patients can start booking you right away.')}
          </Text>
          <Button component="a" href="/doctor/schedule" size="lg" radius="xl" color="teal">
            {t('onboarding.complete.cta', 'Manage availability')}
          </Button>
        </Stack>
      )
    default:
      return null
  }
}

DoctorOnboardingPage.layout = (page: any) => page

export default DoctorOnboardingPage

const normalizeDoctor = (doctor: DoctorForm): DoctorForm => ({
  title: doctor.title || '',
  first_name: doctor.first_name || '',
  last_name: doctor.last_name || '',
  registration_number: doctor.registration_number || '',
  years_of_experience: doctor.years_of_experience ?? null,
  specialty_id: doctor.specialty_id || '',
  bio: doctor.bio || '',
  city: doctor.city || '',
  address: doctor.address || '',
  telemedicine_available: doctor.telemedicine_available ?? false,
  consultation_fee: doctor.consultation_fee ?? null
})
