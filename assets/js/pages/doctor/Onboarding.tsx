import {
  Button,
  Card,
  Col,
  Row,
  Progress,
  Typography,
  Steps,
  Form,
  Input,
  InputNumber,
  Select,
  Switch,
  Result,
  Space,
  Flex
} from 'antd'
import {
  IconArrowLeft,
  IconArrowRight,
  IconCheck
} from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import { router } from '@inertiajs/react'
import { useEffect, useMemo } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { useMutation } from '@tanstack/react-query'

import type { AppPageProps } from '@/types/app'

const { Title, Text } = Typography
const { TextArea } = Input

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

  const { control, register, getValues, reset, setValue, watch, trigger } = useForm<DoctorForm>({
    defaultValues: normalizedDoctor
  })

  // Watch values for controlled inputs that might need re-render
  const watchedValues = watch()

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

  const nextStep = async () => {
    if (currentStep === 'welcome') {
      router.get('/onboarding/doctor?step=personal')
      return
    }

    const isValid = await trigger()
    if (isValid) {
      mutation.mutate({ values: getValues(), step: currentStep })
    }
  }

  const prevStep = () => {
    const idx = STEPS_ORDER.indexOf(currentStep)
    const prev = STEPS_ORDER[Math.max(0, idx - 1)]
    router.get(`/onboarding/doctor?step=${prev}`)
  }

  return (
    <div className="min-h-screen bg-slate-900 text-white" style={{ background: 'linear-gradient(to bottom right, #0f172a, #1e293b, #0f172a)', minHeight: '100vh', padding: '40px 0' }}>
      <div style={{ maxWidth: 800, margin: '0 auto', padding: '0 24px' }}>
        <Flex vertical gap="large">
          <Flex justify="space-between" align="center">
            <div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <img src="/images/logo-medic.svg" alt="Medic" style={{ height: 32 }} />
                <span style={{ fontFamily: 'DM Sans, sans-serif', fontWeight: 700, fontSize: 24, color: 'white', lineHeight: 1 }}>medic</span>
              </div>
              <div style={{ fontSize: 14, opacity: 0.8, marginTop: 4 }}>Doctor Portal</div>
            </div>
            <Button type="text" href="/logout" onClick={(e) => { e.preventDefault(); router.visit('/logout', { method: 'delete' }) }} style={{ color: 'white' }}>
              {t('onboarding.sign_out', 'Sign out')}
            </Button>
          </Flex>

          <Flex vertical gap="small">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <Text style={{ color: 'rgba(255,255,255,0.7)', textTransform: 'uppercase', fontSize: 12, fontWeight: 600 }}>
                {t('onboarding.progress', 'Profile progress')}
              </Text>
              <Text strong style={{ color: 'white' }}>{progress}%</Text>
            </div>
            <Progress percent={progress} showInfo={false} strokeColor="#0d9488" trailColor="rgba(255,255,255,0.2)" />
            <Space size={[8, 8]} wrap>
              {STEPS_ORDER.filter((s) => s !== 'complete').map((s, idx) => {
                const active = s === currentStep
                const completed = idx < stepIndex
                return (
                  <Button
                    key={s}
                    type={active ? 'primary' : 'default'}
                    shape="round"
                    size="small"
                    style={{
                      borderColor: active || completed ? '#0d9488' : 'rgba(255,255,255,0.2)',
                      backgroundColor: active ? '#0d9488' : 'transparent',
                      color: active ? 'white' : 'rgba(255,255,255,0.7)'
                    }}
                  >
                    {t(`onboarding.step.${s}`, s)}
                  </Button>
                )
              })}
            </Space>
          </Flex>

          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 20 }}>
            <Card
              style={{ width: '100%', maxWidth: 600, borderRadius: 24, boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04)' }}
              bodyStyle={{ padding: 40 }}
            >
              {renderStep(currentStep, control, register, specialties, t)}
            </Card>
          </div>

          {!isComplete && (
            <Flex justify="space-between" style={{ maxWidth: 600, margin: '0 auto', width: '100%' }}>
              {currentStep !== 'welcome' ? (
                <Button type="text" icon={<IconArrowLeft size={18} />} onClick={prevStep} style={{ color: 'white' }}>
                  {t('onboarding.back', 'Back')}
                </Button>
              ) : (
                <div />
              )}

              <Button
                type="primary"
                size="large"
                shape="round"
                icon={<IconArrowRight size={20} />}
                iconPosition="end"
                onClick={nextStep}
                loading={mutation.isPending}
                disabled={mutation.isPending}
                style={{ backgroundColor: '#0d9488', borderColor: '#0d9488' }}
              >
                {currentStep === 'pricing'
                  ? t('onboarding.finish', 'Submit profile')
                  : currentStep === 'welcome'
                    ? t('onboarding.lets_start', "Let's start")
                    : t('onboarding.next', 'Continue')}
              </Button>
            </Flex>
          )}
        </Flex>
      </div>
    </div>
  )
}

const renderStep = (
  step: Step,
  control: any,
  register: any,
  specialties: { id: string; name: string }[],
  t: any
) => {

  switch (step) {
    case 'welcome':
      return (
        <Flex vertical gap="large" align="flex-start">
          <div style={{ width: 56, height: 56, borderRadius: '50%', backgroundColor: '#e6fffa', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#0d9488' }}>
            <IconCheck size={28} />
          </div>
          <Title level={2} style={{ margin: 0 }}>{t('onboarding.welcome.title', 'Welcome to Medic')}</Title>
          <Text type="secondary" style={{ fontSize: 18 }}>
            {t('onboarding.welcome.copy', 'Think of this as a guided intro—answer a few friendly questions and we will shape your booking profile.')}
          </Text>
        </Flex>
      )
    case 'personal':
      return (
        <Flex vertical gap="middle">
          <div>
            <Title level={3} style={{ margin: 0 }}>{t('onboarding.personal.title', 'Tell us about you')}</Title>
            <Text type="secondary">{t('onboarding.personal.helper', 'A warm introduction helps patients know they are in excellent hands.')}</Text>
          </div>

          <Row gutter={16}>
            <Col span={8}>
              <div style={{ marginBottom: 8 }}><Text strong>Title</Text></div>
              <Controller
                name="title"
                control={control}
                render={({ field }) => <Input {...field} placeholder="Dr." />}
              />
            </Col>
            <Col span={16}>
              <div style={{ marginBottom: 8 }}><Text strong>First Name</Text></div>
              <Controller
                name="first_name"
                control={control}
                rules={{ required: true }}
                render={({ field }) => <Input {...field} />}
              />
            </Col>
          </Row>

          <div>
            <div style={{ marginBottom: 8 }}><Text strong>Last Name</Text></div>
            <Controller
              name="last_name"
              control={control}
              rules={{ required: true }}
              render={({ field }) => <Input {...field} />}
            />
          </div>

          <Row gutter={16}>
            <Col span={12}>
              <div style={{ marginBottom: 8 }}><Text strong>Registration No.</Text></div>
              <Controller
                name="registration_number"
                control={control}
                render={({ field }) => <Input {...field} />}
              />
            </Col>
            <Col span={12}>
              <div style={{ marginBottom: 8 }}><Text strong>Experience (Years)</Text></div>
              <Controller
                name="years_of_experience"
                control={control}
                render={({ field }) => <InputNumber style={{ width: '100%' }} min={0} {...field} />}
              />
            </Col>
          </Row>
        </Flex>
      )
    case 'specialty':
      return (
        <Flex vertical gap="middle">
          <div>
            <Title level={3} style={{ margin: 0 }}>{t('onboarding.specialty.title', 'What is your area of expertise?')}</Title>
          </div>

          <div>
            <div style={{ marginBottom: 8 }}><Text strong>Specialty</Text></div>
            <Controller
              name="specialty_id"
              control={control}
              render={({ field }) => (
                <Select
                  {...field}
                  style={{ width: '100%' }}
                  placeholder={t('onboarding.specialty.placeholder', 'Select your specialty')}
                  showSearch
                  filterOption={(input, option) =>
                    (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                  }
                  options={specialties.map(s => ({ value: s.id, label: s.name }))}
                />
              )}
            />
          </div>

          <div>
            <div style={{ marginBottom: 8 }}><Text strong>Professional Bio</Text></div>
            <Controller
              name="bio"
              control={control}
              render={({ field }) => (
                <TextArea
                  {...field}
                  placeholder={t('onboarding.specialty.helper', 'Share a short paragraph highlighting your style and focus areas.')}
                  autoSize={{ minRows: 4 }}
                />
              )}
            />
          </div>
        </Flex>
      )
    case 'location':
      return (
        <Flex vertical gap="middle">
          <div>
            <Title level={3} style={{ margin: 0 }}>{t('onboarding.location.title', 'Where do you meet patients?')}</Title>
          </div>

          <Row gutter={16}>
            <Col span={12}>
              <div style={{ marginBottom: 8 }}><Text strong>City</Text></div>
              <Controller
                name="city"
                control={control}
                render={({ field }) => <Input {...field} />}
              />
            </Col>
            <Col span={12}>
              <div style={{ marginBottom: 8 }}><Text strong>Street Address</Text></div>
              <Controller
                name="address"
                control={control}
                render={({ field }) => <Input {...field} />}
              />
            </Col>
          </Row>

          <Card bordered size="small">
            <Controller
              name="telemedicine_available"
              control={control}
              render={({ field }) => (
                <Flex justify="space-between" align="center">
                  <Text>{t('onboarding.location.telemedicine', 'Offer telemedicine appointments?')}</Text>
                  <Switch checked={field.value} onChange={field.onChange} />
                </Flex>
              )}
            />
          </Card>
        </Flex>
      )
    case 'pricing':
      return (
        <Flex vertical gap="middle">
          <div>
            <Title level={3} style={{ margin: 0 }}>{t('onboarding.pricing.title', 'Set your consultation fee')}</Title>
            <Text type="secondary">{t('onboarding.pricing.helper', 'Transparency builds trust—you can always fine-tune later.')}</Text>
          </div>

          <div>
            <Controller
              name="consultation_fee"
              control={control}
              render={({ field }) => (
                <InputNumber
                  {...field}
                  style={{ width: '100%' }}
                  size="large"
                  prefix="€"
                  min={0}
                  step={5}
                  placeholder="60"
                />
              )}
            />
          </div>
        </Flex>
      )
    case 'complete':
      return (
        <Flex vertical gap="large" align="center" style={{ textAlign: 'center', padding: '20px 0' }}>
          <div style={{ position: 'relative' }}>
            <Progress type="circle" percent={100} width={120} strokeColor="#0d9488" format={() => <IconCheck size={48} color="#0d9488" />} />
          </div>

          <div>
            <Title level={2} style={{ margin: 0 }}>{t('onboarding.complete.title', 'Profile ready!')}</Title>
            <Text type="secondary" style={{ maxWidth: 440, margin: '16px auto' }}>
              {t('onboarding.complete.helper', 'Next stop: availability. Set your calendar so patients can start booking you right away.')}
            </Text>
          </div>

          <Button type="primary" size="large" shape="round" href="/doctor/schedule" style={{ backgroundColor: '#0d9488' }}>
            {t('onboarding.complete.cta', 'Manage availability')}
          </Button>
        </Flex>
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

