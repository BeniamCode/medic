import {
  Button,
  Card,
  Col,
  Row,
  Progress,
  Typography,
  Input,
  InputNumber,
  Select,
  Switch,
  Space,
  Flex,
  theme,
  Divider,
  message,
  Alert
} from 'antd'
import {
  IconArrowLeft,
  IconArrowRight,
  IconCheck,
  IconUser,
  IconStethoscope,
  IconMapPin,
  IconCurrencyEuro
} from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import { router } from '@inertiajs/react'
import { useEffect, useMemo, useState } from 'react'
import { Controller, useForm } from 'react-hook-form'

import type { AppPageProps } from '@/types/app'

const { Title, Text } = Typography
const { TextArea } = Input

const STEPS_ORDER = ['welcome', 'personal', 'specialty', 'location', 'pricing', 'complete'] as const

type Step = (typeof STEPS_ORDER)[number]

// Convert camelCase to snake_case for field names
const camelToSnake = (str: string): string =>
  str.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`)

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

const STEP_ICONS: Record<string, React.ReactNode> = {
  welcome: <IconCheck size={20} />,
  personal: <IconUser size={20} />,
  specialty: <IconStethoscope size={20} />,
  location: <IconMapPin size={20} />,
  pricing: <IconCurrencyEuro size={20} />,
  complete: <IconCheck size={20} />
}

// Field validation rules per step
const STEP_VALIDATION: Record<Step, (keyof DoctorForm)[]> = {
  welcome: [],
  personal: ['first_name', 'last_name'],
  specialty: [],
  location: [],
  pricing: [],
  complete: []
}

const DoctorOnboardingPage = ({ step, steps, doctor, specialties, errors: serverErrors }: PageProps) => {
  const { t } = useTranslation('default')
  const { token } = theme.useToken()
  const [messageApi, contextHolder] = message.useMessage()

  // Memoize to prevent infinite re-renders
  const normalizedDoctor = useMemo(() => normalizeDoctor(doctor), [doctor])

  const {
    control,
    getValues,
    trigger,
    setError,
    formState: { errors: formErrors }
  } = useForm<DoctorForm>({
    defaultValues: normalizedDoctor,
    mode: 'onBlur' // Validate on blur for better UX
  })

  // Display server errors (convert camelCase to snake_case)
  useEffect(() => {
    if (!serverErrors) return

    Object.entries(serverErrors).forEach(([field, messages]) => {
      const firstMessage = Array.isArray(messages) ? messages[0] : undefined
      if (!firstMessage) return

      // Convert camelCase to snake_case (e.g., firstName -> first_name)
      const snakeField = camelToSnake(field) as keyof DoctorForm
      setError(snakeField, { type: 'server', message: firstMessage })
    })

    // Show a general error message if there are server errors
    if (Object.keys(serverErrors).length > 0) {
      messageApi.error(t('Please fix the errors below to continue.'))
    }
  }, [serverErrors, setError, messageApi, t])

  const currentStep = useMemo<Step>(() => (steps.includes(step) ? (step as Step) : 'welcome'), [step, steps])
  const stepIndex = STEPS_ORDER.indexOf(currentStep)
  const isComplete = currentStep === 'complete'
  const progress = Math.round((stepIndex / (STEPS_ORDER.length - 1)) * 100)

  const [isSubmitting, setIsSubmitting] = useState(false)

  const nextStep = async () => {
    if (currentStep === 'welcome') {
      router.get('/onboarding/doctor?step=personal')
      return
    }

    // Get required fields for current step
    const requiredFields = STEP_VALIDATION[currentStep]

    // Trigger validation for required fields
    let isValid = true
    if (requiredFields.length > 0) {
      isValid = await trigger(requiredFields)
    }

    if (!isValid) {
      messageApi.warning(t('Please fill in all required fields.'))
      return
    }

    const values = getValues()

    // Debug: Log what we're sending
    console.log('Submitting form:', { step: currentStep, values })

    setIsSubmitting(true)
    router.post(
      `/onboarding/doctor?step=${currentStep}`,
      { doctor: values },
      {
        preserveScroll: true,
        onSuccess: () => {
          console.log('Form submitted successfully')
          setIsSubmitting(false)
        },
        onError: (errors) => {
          console.error('Form submission error:', errors)
          messageApi.error(t('An error occurred. Please try again.'))
          setIsSubmitting(false)
        },
        onFinish: () => {
          setIsSubmitting(false)
        }
      }
    )
  }

  const prevStep = () => {
    const idx = STEPS_ORDER.indexOf(currentStep)
    const prev = STEPS_ORDER[Math.max(0, idx - 1)]
    router.get(`/onboarding/doctor?step=${prev}`)
  }

  // Helper to get error message for a field
  const getFieldError = (fieldName: keyof DoctorForm): string | undefined => {
    return formErrors[fieldName]?.message ||
      (serverErrors?.[fieldName]?.[0])
  }

  return (
    <div style={{
      minHeight: '100vh',
      background: token.colorBgLayout,
      padding: '40px 24px'
    }}>
      {contextHolder}
      <div style={{ maxWidth: 800, margin: '0 auto' }}>
        <Flex vertical gap="large">
          {/* Header */}
          <Flex justify="space-between" align="center">
            <Flex align="center" gap={8}>
              <img src="/images/logo-medic-sun.svg" alt="Medic" style={{ height: 32 }} />
              <span style={{
                fontFamily: 'DM Sans, sans-serif',
                fontWeight: 700,
                fontSize: 24,
                color: token.colorText,
                lineHeight: 1
              }}>
                medic
              </span>
            </Flex>
            <Button
              type="text"
              onClick={(e) => {
                e.preventDefault()
                const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''
                router.delete('/logout', { headers: { 'X-CSRF-Token': csrfToken } })
              }}
            >
              {t('Sign out')}
            </Button>
          </Flex>

          {/* Progress Section */}
          <Card
            variant="outlined"
            style={{ borderRadius: 16 }}
            styles={{ body: { padding: 24 } }}
          >
            <Flex vertical gap="middle">
              <Flex justify="space-between" align="center">
                <div>
                  <Text type="secondary" style={{
                    textTransform: 'uppercase',
                    fontSize: 12,
                    fontWeight: 600,
                    letterSpacing: '0.5px'
                  }}>
                    {t('Profile setup')}
                  </Text>
                  <Title level={4} style={{ margin: '4px 0 0' }}>
                    {t('Complete your doctor profile')}
                  </Title>
                </div>
                <div style={{
                  background: token.colorPrimaryBg,
                  color: token.colorPrimary,
                  padding: '8px 16px',
                  borderRadius: 20,
                  fontWeight: 600
                }}>
                  {progress}%
                </div>
              </Flex>

              <Progress
                percent={progress}
                showInfo={false}
                strokeColor={token.colorPrimary}
                style={{ margin: '8px 0' }}
              />

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
                      icon={completed ? <IconCheck size={14} /> : STEP_ICONS[s]}
                      style={{
                        borderColor: active ? token.colorPrimary : completed ? token.colorPrimary : token.colorBorder,
                        backgroundColor: active ? token.colorPrimary : completed ? token.colorPrimaryBg : 'transparent',
                        color: active ? '#fff' : completed ? token.colorPrimary : token.colorTextSecondary
                      }}
                    >
                      {t(s)}
                    </Button>
                  )
                })}
              </Space>
            </Flex>
          </Card>

          {/* Server Error Alert */}
          {serverErrors && Object.keys(serverErrors).length > 0 && (
            <Alert
              title={t('Validation Error')}
              description={t('Please correct the highlighted fields below.')}
              type="error"
              showIcon
              closable
            />
          )}

          {/* Main Form Card */}
          <Card
            variant="outlined"
            style={{
              borderRadius: 16,
              boxShadow: '0 4px 24px rgba(0, 0, 0, 0.06)'
            }}
            styles={{ body: { padding: 32 } }}
          >
            {renderStep(currentStep, control, specialties, t, token, getFieldError)}
          </Card>

          {/* Action Buttons */}
          {!isComplete && (
            <Flex justify="space-between" style={{ marginTop: 8 }}>
              {currentStep !== 'welcome' ? (
                <Button
                  type="text"
                  icon={<IconArrowLeft size={18} />}
                  onClick={prevStep}
                  size="large"
                  disabled={isSubmitting}
                >
                  {t('Back')}
                </Button>
              ) : (
                <div />
              )}

              <Button
                type="primary"
                size="large"
                shape="round"
                onClick={nextStep}
                loading={isSubmitting}
                disabled={isSubmitting}
              >
                {currentStep === 'pricing'
                  ? t('Submit profile')
                  : currentStep === 'welcome'
                    ? t("Let's start")
                    : t('Continue')}
                {!isSubmitting && <IconArrowRight size={20} style={{ marginLeft: 8 }} />}
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
  specialties: { id: string; name: string }[],
  t: any,
  token: any,
  getFieldError: (field: keyof DoctorForm) => string | undefined
) => {
  switch (step) {
    case 'welcome':
      return (
        <Flex vertical gap="large" align="flex-start">
          <div style={{
            width: 64,
            height: 64,
            borderRadius: '50%',
            backgroundColor: token.colorPrimaryBg,
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            color: token.colorPrimary
          }}>
            <IconCheck size={32} />
          </div>
          <div>
            <Title level={2} style={{ margin: 0 }}>{t('Welcome to Medic')}</Title>
            <Text type="secondary" style={{ fontSize: 16, marginTop: 8, display: 'block' }}>
              {t('Think of this as a guided intro—answer a few friendly questions and we will shape your booking profile.')}
            </Text>
          </div>
          <Divider style={{ margin: '8px 0' }} />
          <Flex gap="middle" wrap="wrap">
            {[
              { icon: <IconUser size={20} />, text: t('Personal info') },
              { icon: <IconStethoscope size={20} />, text: t('Specialty') },
              { icon: <IconMapPin size={20} />, text: t('Location') },
              { icon: <IconCurrencyEuro size={20} />, text: t('Pricing') }
            ].map((item, idx) => (
              <Flex
                key={idx}
                align="center"
                gap={8}
                style={{
                  padding: '8px 16px',
                  background: token.colorFillQuaternary,
                  borderRadius: 8
                }}
              >
                <span style={{ color: token.colorPrimary }}>{item.icon}</span>
                <Text>{item.text}</Text>
              </Flex>
            ))}
          </Flex>
        </Flex>
      )

    case 'personal':
      return (
        <Flex vertical gap="middle">
          <div>
            <Title level={3} style={{ margin: 0 }}>{t('Tell us about you')}</Title>
            <Text type="secondary">{t('A warm introduction helps patients know they are in excellent hands.')}</Text>
          </div>

          <Row gutter={16}>
            <Col span={8}>
              <div style={{ marginBottom: 8 }}><Text strong>{t('Title')}</Text></div>
              <Controller
                name="title"
                control={control}
                render={({ field }) => (
                  <Input
                    value={field.value ?? ''}
                    onChange={field.onChange}
                    onBlur={field.onBlur}
                    placeholder="Dr."
                  />
                )}
              />
            </Col>
            <Col span={16}>
              <div style={{ marginBottom: 8 }}>
                <Text strong>{t('First Name')}</Text>
                <Text type="danger"> *</Text>
              </div>
              <Controller
                name="first_name"
                control={control}
                rules={{ required: t('First name is required') }}
                render={({ field }) => (
                  <Input
                    value={field.value ?? ''}
                    onChange={field.onChange}
                    onBlur={field.onBlur}
                    status={getFieldError('first_name') ? 'error' : undefined}
                  />
                )}
              />
              {getFieldError('first_name') && (
                <Text type="danger" style={{ fontSize: 12 }}>{getFieldError('first_name')}</Text>
              )}
            </Col>
          </Row>

          <div>
            <div style={{ marginBottom: 8 }}>
              <Text strong>{t('Last Name')}</Text>
              <Text type="danger"> *</Text>
            </div>
            <Controller
              name="last_name"
              control={control}
              rules={{ required: t('Last name is required') }}
              render={({ field }) => (
                <Input
                  value={field.value ?? ''}
                  onChange={field.onChange}
                  onBlur={field.onBlur}
                  status={getFieldError('last_name') ? 'error' : undefined}
                />
              )}
            />
            {getFieldError('last_name') && (
              <Text type="danger" style={{ fontSize: 12 }}>{getFieldError('last_name')}</Text>
            )}
          </div>

          <Row gutter={16}>
            <Col span={12}>
              <div style={{ marginBottom: 8 }}><Text strong>{t('Registration No.')}</Text></div>
              <Controller
                name="registration_number"
                control={control}
                render={({ field }) => (
                  <Input
                    value={field.value ?? ''}
                    onChange={field.onChange}
                    onBlur={field.onBlur}
                  />
                )}
              />
            </Col>
            <Col span={12}>
              <div style={{ marginBottom: 8 }}><Text strong>{t('Experience (Years)')}</Text></div>
              <Controller
                name="years_of_experience"
                control={control}
                render={({ field }) => (
                  <InputNumber
                    style={{ width: '100%' }}
                    min={0}
                    value={field.value}
                    onChange={field.onChange}
                    onBlur={field.onBlur}
                  />
                )}
              />
            </Col>
          </Row>
        </Flex>
      )

    case 'specialty':
      return (
        <Flex vertical gap="middle">
          <div>
            <Title level={3} style={{ margin: 0 }}>{t('What is your area of expertise?')}</Title>
            <Text type="secondary">{t('Help patients find you by selecting your specialty.')}</Text>
          </div>

          <div>
            <div style={{ marginBottom: 8 }}><Text strong>{t('Specialty')}</Text></div>
            <Controller
              name="specialty_id"
              control={control}
              render={({ field }) => (
                <Select
                  value={field.value || undefined}
                  onChange={field.onChange}
                  onBlur={field.onBlur}
                  style={{ width: '100%' }}
                  placeholder={t('Select your specialty')}
                  showSearch
                  allowClear
                  filterOption={(input, option) =>
                    (option?.label ?? '').toLowerCase().includes(input.toLowerCase())
                  }
                  options={specialties.map(s => ({ value: s.id, label: s.name }))}
                />
              )}
            />
          </div>

          <div>
            <div style={{ marginBottom: 8 }}><Text strong>{t('Professional Bio')}</Text></div>
            <Controller
              name="bio"
              control={control}
              render={({ field }) => (
                <TextArea
                  value={field.value ?? ''}
                  onChange={field.onChange}
                  onBlur={field.onBlur}
                  placeholder={t('Share a short paragraph highlighting your style and focus areas.')}
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
            <Title level={3} style={{ margin: 0 }}>{t('Where do you meet patients?')}</Title>
            <Text type="secondary">{t('Your location helps patients find doctors near them.')}</Text>
          </div>

          <Row gutter={16}>
            <Col span={12}>
              <div style={{ marginBottom: 8 }}><Text strong>{t('City')}</Text></div>
              <Controller
                name="city"
                control={control}
                render={({ field }) => (
                  <Input
                    value={field.value ?? ''}
                    onChange={field.onChange}
                    onBlur={field.onBlur}
                  />
                )}
              />
            </Col>
            <Col span={12}>
              <div style={{ marginBottom: 8 }}><Text strong>{t('Street Address')}</Text></div>
              <Controller
                name="address"
                control={control}
                render={({ field }) => (
                  <Input
                    value={field.value ?? ''}
                    onChange={field.onChange}
                    onBlur={field.onBlur}
                  />
                )}
              />
            </Col>
          </Row>

          <Card size="small" variant="outlined">
            <Controller
              name="telemedicine_available"
              control={control}
              render={({ field }) => (
                <Flex justify="space-between" align="center">
                  <div>
                    <Text strong>{t('Offer telemedicine appointments?')}</Text>
                    <br />
                    <Text type="secondary" style={{ fontSize: 12 }}>
                      {t('Allow patients to book video consultations')}
                    </Text>
                  </div>
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
            <Title level={3} style={{ margin: 0 }}>{t('Set your consultation fee')}</Title>
            <Text type="secondary">{t('Transparency builds trust—you can always fine-tune later.')}</Text>
          </div>

          <div>
            <div style={{ marginBottom: 8 }}><Text strong>{t('Standard consultation fee')}</Text></div>
            <Controller
              name="consultation_fee"
              control={control}
              render={({ field }) => (
                <InputNumber
                  value={field.value}
                  onChange={field.onChange}
                  onBlur={field.onBlur}
                  style={{ width: '100%' }}
                  size="large"
                  prefix="€"
                  min={0}
                  step={5}
                  placeholder="60"
                />
              )}
            />
            <Text type="secondary" style={{ fontSize: 12, marginTop: 8, display: 'block' }}>
              {t('You can set different fees for different appointment types later.')}
            </Text>
          </div>
        </Flex>
      )

    case 'complete':
      return (
        <Flex vertical gap="large" align="center" style={{ textAlign: 'center', padding: '24px 0' }}>
          <div style={{ position: 'relative' }}>
            <Progress
              type="circle"
              percent={100}
              size={120}
              strokeColor={token.colorPrimary}
              format={() => <IconCheck size={48} color={token.colorPrimary} />}
            />
          </div>

          <div>
            <Title level={2} style={{ margin: 0 }}>{t('Profile ready!')}</Title>
            <Text type="secondary" style={{ maxWidth: 440, margin: '16px auto', display: 'block' }}>
              {t('Next stop: availability. Set your calendar so patients can start booking you right away.')}
            </Text>
          </div>

          <Button
            type="primary"
            size="large"
            shape="round"
            href="/doctor/schedule"
          >
            {t('Manage availability')}
          </Button>
        </Flex>
      )

    default:
      return null
  }
}

DoctorOnboardingPage.layout = (page: any) => page

export default DoctorOnboardingPage

const normalizeDoctor = (doctor: any): DoctorForm => ({
  // Handle both camelCase (from Inertia) and snake_case (fallback)
  title: doctor?.title || '',
  first_name: doctor?.firstName || doctor?.first_name || '',
  last_name: doctor?.lastName || doctor?.last_name || '',
  registration_number: doctor?.registrationNumber || doctor?.registration_number || '',
  years_of_experience: doctor?.yearsOfExperience ?? doctor?.years_of_experience ?? null,
  specialty_id: doctor?.specialtyId || doctor?.specialty_id || null,
  bio: doctor?.bio || '',
  city: doctor?.city || '',
  address: doctor?.address || '',
  telemedicine_available: doctor?.telemedicineAvailable ?? doctor?.telemedicine_available ?? false,
  consultation_fee: doctor?.consultationFee ?? doctor?.consultation_fee ?? null
})
