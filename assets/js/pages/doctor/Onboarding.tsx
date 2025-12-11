import { ActionIcon, Box, Button, Card, Center, Container, Grid, Group, NumberInput, Progress, RingProgress, Select, Stack, Switch, Text, Textarea, TextInput, ThemeIcon, Title, rem } from '@mantine/core'
import { IconArrowLeft, IconArrowRight, IconCheck, IconLogout } from '@tabler/icons-react'
import { useForm } from '@mantine/form'
import { Link, router } from '@inertiajs/react'
import { useMemo } from 'react'
import { useTranslation } from 'react-i18next'

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

  // Normalize incoming camelCase props to snake_case for the form
  const initialValues: DoctorForm = {
    title: doctor.title,
    first_name: (doctor as any).firstName,
    last_name: (doctor as any).lastName,
    registration_number: (doctor as any).registrationNumber,
    years_of_experience: (doctor as any).yearsOfExperience,
    specialty_id: (doctor as any).specialtyId,
    bio: doctor.bio,
    city: doctor.city,
    address: doctor.address,
    telemedicine_available: (doctor as any).telemedicineAvailable,
    consultation_fee: (doctor as any).consultationFee
  }

  const form = useForm<DoctorForm>({ initialValues })

  const currentStep = useMemo<Step>(() => (steps.includes(step) ? (step as Step) : 'welcome'), [step, steps])
  const stepIndex = STEPS_ORDER.indexOf(currentStep)

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
    <Box h="100vh" w="100vw" style={{ overflow: 'hidden' }}>
      <Grid h="100%" gutter={0}>

        {/* Left Sidebar - Navigation */}
        <Grid.Col span={3} h="100%" bg="gray.0" style={{ borderRight: '1px solid var(--mantine-color-gray-2)' }}>
          <Stack justify="space-between" h="100%" p="xl">
            <Box>
              <Group mb={60} px="xs">
                <img src="/images/logo-medic.svg" alt="Medic" style={{ height: 32 }} />
              </Group>

              <Stack gap="lg" px="xs">
                {STEPS_ORDER.filter(s => s !== 'complete').map((s, idx) => {
                  const isActive = s === currentStep
                  const isCompleted = idx < stepIndex

                  return (
                    <Group key={s} gap="md" style={{ opacity: isActive || isCompleted ? 1 : 0.5, transition: 'opacity 0.2s' }}>
                      {isCompleted ? (
                        <ThemeIcon color="teal" variant="light" radius="xl" size="md">
                          <IconCheck size={14} />
                        </ThemeIcon>
                      ) : (
                        <ThemeIcon variant={isActive ? "filled" : "outline"} color="teal" radius="xl" size="md">
                          <Text size="xs" fw={700}>{idx + 1}</Text>
                        </ThemeIcon>
                      )}
                      <Text fw={isActive ? 700 : 500} size="sm" tt="capitalize" c={isActive ? 'teal.9' : 'dimmed'}>
                        {s === 'personal' ? 'Personal Info' : s}
                      </Text>
                    </Group>
                  )
                })}
              </Stack>
            </Box>

            <Group px="xs">
              <Button
                variant="subtle"
                color="gray"
                size="xs"
                leftSection={<IconLogout size={14} />}
                component={Link}
                href="/logout"
                method="delete"
                as="button"
              >
                Sign Out
              </Button>
            </Group>
          </Stack>
        </Grid.Col>

        {/* Main Content - Centered Form */}
        <Grid.Col span={9} h="100%" bg="white" style={{ position: 'relative' }}>
          <Center h="100%">
            <Container size="sm" w="100%">

              {/* Step Content */}
              <Box mb={80} style={{ animation: 'fadeIn 0.4s ease-out' }}>
                {renderStep(currentStep, form, specialties, t)}
              </Box>

              {/* Navigation Buttons */}
              {!isComplete && (
                <Group justify="space-between" mt={50}>
                  {currentStep !== 'welcome' ? (
                    <Button variant="subtle" size="lg" radius="xl" leftSection={<IconArrowLeft size={18} />} onClick={prevStep} c="dimmed">
                      {t('onboarding.back', 'Back')}
                    </Button>
                  ) : (
                    <div />
                  )}

                  <Button
                    size="xl"
                    radius="xl"
                    rightSection={<IconArrowRight size={20} />}
                    onClick={nextStep}
                    color="teal"
                    px={48}
                    style={{ boxShadow: '0 4px 14px rgba(0, 128, 128, 0.2)' }}
                  >
                    {currentStep === 'pricing'
                      ? t('onboarding.finish', 'Submit Profile')
                      : currentStep === 'welcome'
                        ? "Let's Start"
                        : t('onboarding.next', 'Continue')}
                  </Button>
                </Group>
              )}

            </Container>
          </Center>

          {/* Progress Bar Top */}
          <Progress
            value={((stepIndex) / (STEPS_ORDER.length - 1)) * 100}
            size="xs"
            radius={0}
            color="teal"
            style={{ position: 'absolute', top: 0, left: 0, right: 0 }}
          />
        </Grid.Col>
      </Grid>
    </Box>
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
        <Stack gap="lg">
          <ThemeIcon size={60} radius="xl" color="teal" variant="light">
            <IconCheck size={32} />
          </ThemeIcon>
          <Title order={1} size={42} fw={800} lh={1.1}>
            {t('onboarding.welcome.title', 'Welcome to Medic')}
          </Title>
          <Text size="xl" c="dimmed" maw={500} lh={1.6}>
            Let's get your medical practice set up. This will only take about 2 minutes.
          </Text>
        </Stack>
      )
    case 'personal':
      return (
        <Stack gap="lg">
          <Title order={2} size={32}>First, tell us about yourself</Title>
          <Group grow align="start">
            <Box maw={120}>
              <TextInput size="lg" label="Title" placeholder="Dr." {...form.getInputProps('title')} />
            </Box>
            <TextInput size="lg" label="First Name" required {...form.getInputProps('first_name')} />
          </Group>
          <TextInput size="lg" label="Last Name" required {...form.getInputProps('last_name')} />
          <Group grow align="start">
            <TextInput
              size="lg"
              label="Registration Number"
              placeholder="Medical License #"
              {...form.getInputProps('registration_number')}
            />
            <NumberInput
              size="lg"
              label="Years of Experience"
              min={0}
              {...form.getInputProps('years_of_experience')}
            />
          </Group>
        </Stack>
      )
    case 'specialty':
      return (
        <Stack gap="lg">
          <Title order={2} size={32}>What is your area of expertise?</Title>
          <Select
            size="xl"
            data={specialties.map((s) => ({ value: s.id, label: s.name }))}
            label="Specialty"
            placeholder="Select your specialty"
            searchable
            nothingFoundMessage="No options"
            {...form.getInputProps('specialty_id')}
          />
          <Textarea
            size="lg"
            label="Professional Bio"
            description="Briefly describe your background and focus."
            autosize
            minRows={4}
            {...form.getInputProps('bio')}
          />
        </Stack>
      )
    case 'location':
      return (
        <Stack gap="lg">
          <Title order={2} size={32}>Where do you practice?</Title>
          <Group grow align="start">
            <TextInput size="lg" label="City" {...form.getInputProps('city')} />
            <TextInput size="lg" label="Street Address" {...form.getInputProps('address')} />
          </Group>
          <Card withBorder radius="md" p="md" mt="md">
            <Group justify="space-between">
              <Text fw={500}>I offer Telemedicine (Video Calls)</Text>
              <Switch
                size="lg"
                onLabel="YES" offLabel="NO"
                {...form.getInputProps('telemedicine_available', { type: 'checkbox' })}
              />
            </Group>
          </Card>
        </Stack>
      )
    case 'pricing':
      return (
        <Stack gap="lg">
          <Title order={2} size={32}>Set your consultation fee</Title>
          <Text c="dimmed" size="lg">How much do you charge for a standard consultation?</Text>
          <NumberInput
            size="xl"
            leftSection={<Text size="xl" fw={700}>€</Text>}
            placeholder="50"
            min={0}
            step={5}
            styles={{ input: { fontSize: '2rem', height: '80px' } }}
            {...form.getInputProps('consultation_fee')}
          />
        </Stack>
      )
    case 'complete':
      return (
        <Stack gap="xl" align="center" ta="center">
          <RingProgress
            size={180}
            roundCaps
            thickness={16}
            sections={[{ value: 100, color: 'teal' }]}
            label={
              <Center>
                <IconCheck size={60} color="var(--mantine-color-teal-6)" />
              </Center>
            }
          />

          <Title order={1}>All Set!</Title>
          <Text size="lg" c="dimmed" maw={500}>
            Your profile has been created successfully. Now, let's set up your weekly availability schedule.
          </Text>

          <Button
            component="a"
            href="/doctor/schedule"
            size="xl"
            radius="xl"
            color="teal"
            mt="xl"
          >
            Manage Availability
          </Button>
        </Stack>
      )
    default:
      return null
  }
}



DoctorOnboardingPage.layout = (page: any) => page

export default DoctorOnboardingPage
