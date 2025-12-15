import { useEffect, useMemo } from 'react'
import {
  Avatar,
  Button as DesktopButton,
  Card as DesktopCard,
  Col,
  DatePicker,
  Divider,
  Flex,
  Input as DesktopInput,
  Row,
  Space,
  Switch as DesktopSwitch,
  Tag,
  Typography,
  message,
  theme,
  Upload
} from 'antd'
import type { UploadRequestOption } from 'rc-upload/lib/interface'
import dayjs from 'dayjs'
import { Controller, useForm } from 'react-hook-form'
import { useTranslation } from 'react-i18next'
import { useMutation } from '@tanstack/react-query'
import { router } from '@inertiajs/react'
import { useIsMobile } from '@/lib/device'

import type { AppPageProps } from '@/types/app'

// Mobile imports
import { Button as MobileButton, Card as MobileCard, Form as MobileForm, Input as MobileInput, Switch as MobileSwitch, Toast, ImageUploader } from 'antd-mobile'
import type { ImageUploadItem } from 'antd-mobile/es/components/image-uploader'

const { Title, Text } = Typography

type PatientProfile = {
  id: string
  first_name: string | null
  last_name: string | null
  date_of_birth: string | null
  phone: string | null
  emergency_contact: string | null
  profile_image_url: string | null
  preferred_language: string | null
  preferred_timezone: string | null
  communication_preferences: Record<string, any> | null
}

type PageProps = AppPageProps<{
  patient: any
  errors?: Record<string, string[]>
}>

const normalizePatient = (patient: any): PatientProfile => {
  const get = <T,>(snakeKey: string, camelKey: string, fallback: T): T => {
    const snakeVal = patient?.[snakeKey]
    if (snakeVal !== undefined && snakeVal !== null) return snakeVal as T

    const camelVal = patient?.[camelKey]
    if (camelVal !== undefined && camelVal !== null) return camelVal as T

    return fallback
  }

  return {
    id: get('id', 'id', ''),
    first_name: get('first_name', 'firstName', ''),
    last_name: get('last_name', 'lastName', ''),
    date_of_birth: get('date_of_birth', 'dateOfBirth', null),
    phone: get('phone', 'phone', ''),
    emergency_contact: get('emergency_contact', 'emergencyContact', ''),
    profile_image_url: get('profile_image_url', 'profileImageUrl', null),
    preferred_language: get('preferred_language', 'preferredLanguage', 'en'),
    preferred_timezone: get('preferred_timezone', 'preferredTimezone', ''),
    communication_preferences: get('communication_preferences', 'communicationPreferences', {})
  }
}

// =============================================================================
// MOBILE PATIENT PROFILE
// =============================================================================

function MobilePatientProfile({ patient, errors: serverErrors }: { patient: any; errors?: Record<string, string[]> }) {
  const { t } = useTranslation('default')
  const normalizedPatient = useMemo(() => normalizePatient(patient), [patient])

  const {
    control,
    handleSubmit,
    reset,
    setError,
    setValue,
    formState: { errors: formErrors }
  } = useForm<PatientProfile>({
    defaultValues: normalizedPatient
  })

  useEffect(() => {
    reset(normalizedPatient)
  }, [normalizedPatient, reset])

  useEffect(() => {
    if (!serverErrors) return
    Object.entries(serverErrors).forEach(([field, messages]) => {
      const firstMessage = Array.isArray(messages) ? messages[0] : undefined
      if (!firstMessage) return
      setError(field as keyof PatientProfile, { type: 'server', message: firstMessage })
    })
  }, [serverErrors, setError])

  const mutation = useMutation({
    mutationFn: async (values: PatientProfile) =>
      await new Promise<void>((resolve) => {
        router.post(
          '/dashboard/patient/profile',
          { patient: values },
          {
            preserveScroll: true,
            onSuccess: () => {
              Toast.show({ icon: 'success', content: t('patient.profile.saved', 'Profile saved') })
              resolve()
            },
            onError: () => {
              Toast.show({ icon: 'fail', content: t('patient.profile.save_failed', 'Unable to save') })
              resolve()
            }
          }
        )
      })
  })

  const onSubmit = (values: PatientProfile) => mutation.mutate(values)

  return (
    <div style={{ padding: 16, paddingBottom: 100 }}>
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, margin: '0 0 4px' }}>
          {t('patient.profile.title', 'Patient profile')}
        </h2>
        <p style={{ color: '#666', margin: 0, fontSize: 14 }}>
          {t('patient.profile.subtitle', 'Keep your details up to date')}
        </p>
      </div>

      <form onSubmit={handleSubmit(onSubmit)}>
        <MobileCard title="Basic Info" style={{ borderRadius: 12, marginBottom: 16 }}>
          {/* Avatar */}
          <Controller
            name="profile_image_url"
            control={control}
            render={({ field }) => (
              <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 20 }}>
                <Avatar
                  size={80}
                  src={field.value || undefined}
                  style={{ backgroundColor: '#0d9488' }}
                >
                  {normalizedPatient.first_name?.charAt(0) || 'P'}
                </Avatar>
              </div>
            )}
          />

          <MobileForm layout="vertical">
            <div style={{ display: 'flex', gap: 12 }}>
              <MobileForm.Item label={t('patient.profile.first_name', 'First name')} style={{ flex: 1 }}>
                <Controller
                  name="first_name"
                  control={control}
                  render={({ field }) => (
                    <MobileInput
                      placeholder="John"
                      value={field.value || ''}
                      onChange={field.onChange}
                      clearable
                    />
                  )}
                />
              </MobileForm.Item>

              <MobileForm.Item label={t('patient.profile.last_name', 'Last name')} style={{ flex: 1 }}>
                <Controller
                  name="last_name"
                  control={control}
                  render={({ field }) => (
                    <MobileInput
                      placeholder="Doe"
                      value={field.value || ''}
                      onChange={field.onChange}
                      clearable
                    />
                  )}
                />
              </MobileForm.Item>
            </div>

            <MobileForm.Item label={t('patient.profile.dob', 'Date of birth')}>
              <Controller
                name="date_of_birth"
                control={control}
                render={({ field }) => (
                  <MobileInput
                    type="date"
                    value={field.value || ''}
                    onChange={field.onChange}
                  />
                )}
              />
            </MobileForm.Item>

            <MobileForm.Item label={t('patient.profile.phone', 'Phone')}>
              <Controller
                name="phone"
                control={control}
                render={({ field }) => (
                  <MobileInput
                    type="tel"
                    placeholder="+30..."
                    value={field.value || ''}
                    onChange={field.onChange}
                    clearable
                  />
                )}
              />
            </MobileForm.Item>

            <MobileForm.Item label={t('patient.profile.emergency_contact', 'Emergency contact')}>
              <Controller
                name="emergency_contact"
                control={control}
                render={({ field }) => (
                  <MobileInput
                    placeholder="Name + phone"
                    value={field.value || ''}
                    onChange={field.onChange}
                    clearable
                  />
                )}
              />
            </MobileForm.Item>
          </MobileForm>
        </MobileCard>

        <MobileCard title="Preferences" style={{ borderRadius: 12, marginBottom: 16 }}>
          <MobileForm layout="vertical">
            <div style={{ display: 'flex', gap: 12 }}>
              <MobileForm.Item label={t('patient.profile.preferred_language', 'Language')} style={{ flex: 1 }}>
                <Controller
                  name="preferred_language"
                  control={control}
                  render={({ field }) => (
                    <MobileInput
                      placeholder="en / el"
                      value={field.value || ''}
                      onChange={field.onChange}
                    />
                  )}
                />
              </MobileForm.Item>

              <MobileForm.Item label={t('patient.profile.preferred_timezone', 'Timezone')} style={{ flex: 1 }}>
                <Controller
                  name="preferred_timezone"
                  control={control}
                  render={({ field }) => (
                    <MobileInput
                      placeholder="Europe/Athens"
                      value={field.value || ''}
                      onChange={field.onChange}
                    />
                  )}
                />
              </MobileForm.Item>
            </div>

            <div style={{ borderTop: '1px solid #f0f0f0', marginTop: 16, paddingTop: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                <div>
                  <div style={{ fontWeight: 500 }}>{t('patient.profile.pref_email_reminders', 'Email reminders')}</div>
                  <div style={{ fontSize: 12, color: '#999' }}>Appointment confirmations</div>
                </div>
                <Controller
                  name="communication_preferences"
                  control={control}
                  render={({ field }) => (
                    <MobileSwitch
                      checked={!!((field.value || {}).email_reminders ?? true)}
                      onChange={(checked) => {
                        field.onChange({ ...(field.value || {}), email_reminders: checked })
                      }}
                    />
                  )}
                />
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <div>
                  <div style={{ fontWeight: 500 }}>{t('patient.profile.pref_sms_reminders', 'SMS reminders')}</div>
                  <div style={{ fontSize: 12, color: '#999' }}>Optional SMS updates</div>
                </div>
                <Controller
                  name="communication_preferences"
                  control={control}
                  render={({ field }) => (
                    <MobileSwitch
                      checked={!!((field.value || {}).sms_reminders ?? false)}
                      onChange={(checked) => {
                        field.onChange({ ...(field.value || {}), sms_reminders: checked })
                      }}
                    />
                  )}
                />
              </div>
            </div>
          </MobileForm>
        </MobileCard>

        <MobileButton
          block
          color="primary"
          size="large"
          type="submit"
          loading={mutation.isPending}
          style={{ '--border-radius': '8px' }}
        >
          {t('patient.profile.save', 'Save changes')}
        </MobileButton>
      </form>
    </div>
  )
}

// =============================================================================
// DESKTOP PATIENT PROFILE (Original)
// =============================================================================

function DesktopPatientProfile({ patient, errors: serverErrors }: { patient: any; errors?: Record<string, string[]> }) {
  const { t } = useTranslation('default')
  const { token } = theme.useToken()
  const [messageApi, contextHolder] = message.useMessage()

  const normalizedPatient = useMemo(() => normalizePatient(patient), [patient])

  const {
    control,
    handleSubmit,
    reset,
    setError,
    setValue,
    formState: { errors: formErrors }
  } = useForm<PatientProfile>({
    defaultValues: normalizedPatient
  })

  useEffect(() => {
    reset(normalizedPatient)
  }, [normalizedPatient, reset])

  useEffect(() => {
    if (!serverErrors) return

    Object.entries(serverErrors).forEach(([field, messages]) => {
      const firstMessage = Array.isArray(messages) ? messages[0] : undefined
      if (!firstMessage) return
      setError(field as keyof PatientProfile, { type: 'server', message: firstMessage })
    })
  }, [serverErrors, setError])

  const mutation = useMutation({
    mutationFn: async (values: PatientProfile) =>
      await new Promise<void>((resolve) => {
        router.post(
          '/dashboard/patient/profile',
          { patient: values },
          {
            preserveScroll: true,
            onSuccess: () => {
              messageApi.success(t('patient.profile.saved', 'Profile saved'))
              resolve()
            },
            onError: () => {
              messageApi.error(
                t('patient.profile.save_failed', 'Unable to save. Please review the highlighted fields.')
              )
              resolve()
            }
          }
        )
      })
  })

  const onSubmit = (values: PatientProfile) => mutation.mutate(values)

  return (
    <div style={{ padding: 24, maxWidth: 1000, margin: '0 auto' }}>
      {contextHolder}

      <Flex vertical gap="large">
        <DesktopCard
          variant="outlined"
          style={{
            borderRadius: 16,
            background: `linear-gradient(to right, ${token.colorBgContainer}, ${token.colorFillQuaternary})`
          }}
          styles={{ body: { padding: 32 } }}
        >
          <Title level={2} style={{ margin: 0 }}>
            {t('patient.profile.title', 'Patient profile')}
          </Title>
          <Text type="secondary" style={{ marginTop: 8, display: 'block', maxWidth: 620 }}>
            {t(
              'patient.profile.subtitle',
              'Keep your details up to date so we can personalize your experience and help clinics reach you about appointments.'
            )}
          </Text>

          <Flex gap="small" style={{ marginTop: 16 }} wrap>
            <Tag color="blue">{t('patient.profile.badge_private', 'Private')}</Tag>
            <Tag color="cyan">{t('patient.profile.badge_secure', 'Secure data')}</Tag>
          </Flex>
        </DesktopCard>

        <form onSubmit={handleSubmit(onSubmit)}>
          <Flex vertical gap="large">
            <DesktopCard variant="outlined" style={{ borderRadius: 16 }}>
              <Title level={4} style={{ marginTop: 0 }}>
                {t('patient.profile.basic', 'Basic info')}
              </Title>

              <Controller
                name="profile_image_url"
                control={control}
                render={({ field }) => (
                  <div style={{ marginBottom: 24 }}>
                    <div style={{ marginBottom: 8 }}>
                      <Text strong>{t('patient.profile.photo', 'Profile photo')}</Text>
                    </div>

                    <Flex gap="middle" align="center" wrap>
                      <Avatar
                        size={72}
                        src={field.value || undefined}
                        style={{ background: token.colorFillQuaternary, color: token.colorTextSecondary }}
                      >
                        {normalizedPatient.first_name?.charAt(0) || 'P'}
                      </Avatar>

                      <Upload
                        accept="image/png,image/jpeg,image/webp"
                        showUploadList={false}
                        beforeUpload={(file) => {
                          const okType = ['image/png', 'image/jpeg', 'image/webp'].includes(file.type)
                          if (!okType) {
                            messageApi.error(t('patient.profile.photo_type', 'Please upload a JPG, PNG, or WebP image'))
                            return Upload.LIST_IGNORE
                          }
                          const okSize = file.size <= 5 * 1024 * 1024
                          if (!okSize) {
                            messageApi.error(t('patient.profile.photo_size', 'Max file size is 5MB'))
                            return Upload.LIST_IGNORE
                          }
                          return true
                        }}
                        customRequest={async (options: UploadRequestOption) => {
                          try {
                            const formData = new FormData()
                            formData.append('image', options.file as File)

                            const csrf =
                              document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''

                            const res = await fetch('/dashboard/patient/profile/image', {
                              method: 'POST',
                              headers: {
                                'X-Requested-With': 'XMLHttpRequest',
                                'x-csrf-token': csrf
                              },
                              body: formData
                            })

                            const data = await res.json().catch(() => null)

                            if (!res.ok) {
                              messageApi.error(t('patient.profile.photo_failed', 'Unable to upload photo. Please try again.'))
                              throw new Error('upload_failed')
                            }

                            if (!data?.profile_image_url) throw new Error('upload_failed')

                            setValue('profile_image_url', data.profile_image_url, { shouldDirty: true })
                            messageApi.success(t('patient.profile.photo_uploaded', 'Photo updated'))
                            options.onSuccess?.(data as any)
                          } catch (e) {
                            messageApi.error(t('patient.profile.photo_failed', 'Unable to upload photo. Please try again.'))
                            options.onError?.(e as any)
                          }
                        }}
                      >
                        <DesktopButton type="default">{t('patient.profile.photo_upload', 'Upload photo')}</DesktopButton>
                      </Upload>

                      <Text type="secondary" style={{ fontSize: 12, maxWidth: 520 }}>
                        {t('patient.profile.photo_help', 'Use a clear photo. JPG/PNG/WebP up to 5MB.')}
                      </Text>
                    </Flex>
                  </div>
                )}
              />

              <Row gutter={16}>
                <Col xs={24} md={12}>
                  <div style={{ marginBottom: 8 }}>
                    <Text strong>{t('patient.profile.first_name', 'First name')}</Text>
                  </div>
                  <Controller
                    name="first_name"
                    control={control}
                    rules={{ required: true }}
                    render={({ field }) => (
                      <DesktopInput {...field} value={field.value || ''} status={formErrors.first_name ? 'error' : ''} />
                    )}
                  />
                  {formErrors.first_name?.message && <Text type="danger">{formErrors.first_name.message}</Text>}
                </Col>
                <Col xs={24} md={12}>
                  <div style={{ marginBottom: 8 }}>
                    <Text strong>{t('patient.profile.last_name', 'Last name')}</Text>
                  </div>
                  <Controller
                    name="last_name"
                    control={control}
                    rules={{ required: true }}
                    render={({ field }) => (
                      <DesktopInput {...field} value={field.value || ''} status={formErrors.last_name ? 'error' : ''} />
                    )}
                  />
                  {formErrors.last_name?.message && <Text type="danger">{formErrors.last_name.message}</Text>}
                </Col>
              </Row>

              <Divider style={{ margin: '24px 0' }} />

              <Row gutter={16}>
                <Col xs={24} md={12}>
                  <div style={{ marginBottom: 8 }}>
                    <Text strong>{t('patient.profile.dob', 'Date of birth')}</Text>
                  </div>
                  <Controller
                    name="date_of_birth"
                    control={control}
                    render={({ field }) => (
                      <DatePicker
                        value={field.value ? dayjs(field.value) : null}
                        onChange={(value) => field.onChange(value ? value.format('YYYY-MM-DD') : null)}
                        style={{ width: '100%' }}
                      />
                    )}
                  />
                </Col>
                <Col xs={24} md={12}>
                  <div style={{ marginBottom: 8 }}>
                    <Text strong>{t('patient.profile.phone', 'Phone')}</Text>
                  </div>
                  <Controller
                    name="phone"
                    control={control}
                    render={({ field }) => (
                      <DesktopInput {...field} value={field.value || ''} placeholder="+30..." status={formErrors.phone ? 'error' : ''} />
                    )}
                  />
                  {formErrors.phone?.message && <Text type="danger">{formErrors.phone.message}</Text>}
                </Col>
              </Row>

              <Row gutter={16} style={{ marginTop: 16 }}>
                <Col xs={24} md={24}>
                  <div style={{ marginBottom: 8 }}>
                    <Text strong>{t('patient.profile.emergency_contact', 'Emergency contact')}</Text>
                  </div>
                  <Controller
                    name="emergency_contact"
                    control={control}
                    render={({ field }) => (
                      <DesktopInput {...field} value={field.value || ''} placeholder={t('patient.profile.emergency_placeholder', 'Name + phone')} />
                    )}
                  />
                </Col>
              </Row>
            </DesktopCard>

            <DesktopCard variant="outlined" style={{ borderRadius: 16 }}>
              <Title level={4} style={{ marginTop: 0 }}>
                {t('patient.profile.preferences', 'Preferences')}
              </Title>
              <Text type="secondary" style={{ display: 'block', marginBottom: 16 }}>
                {t('patient.profile.preferences_help', 'These help us tailor notifications and the experience.')}
              </Text>

              <Row gutter={16}>
                <Col xs={24} md={12}>
                  <div style={{ marginBottom: 8 }}>
                    <Text strong>{t('patient.profile.preferred_language', 'Preferred language')}</Text>
                  </div>
                  <Controller
                    name="preferred_language"
                    control={control}
                    render={({ field }) => (
                      <DesktopInput {...field} value={field.value || ''} placeholder="en / el" />
                    )}
                  />
                </Col>
                <Col xs={24} md={12}>
                  <div style={{ marginBottom: 8 }}>
                    <Text strong>{t('patient.profile.preferred_timezone', 'Preferred timezone')}</Text>
                  </div>
                  <Controller
                    name="preferred_timezone"
                    control={control}
                    render={({ field }) => <DesktopInput {...field} value={field.value || ''} placeholder="Europe/Athens" />}
                  />
                </Col>
              </Row>

              <Divider style={{ margin: '24px 0' }} />

              <Space direction="vertical" size="middle" style={{ width: '100%' }}>
                <Flex justify="space-between" align="center">
                  <div>
                    <Text strong>{t('patient.profile.pref_email_reminders', 'Email reminders')}</Text>
                    <Text type="secondary" style={{ display: 'block', fontSize: 12 }}>
                      {t('patient.profile.pref_email_reminders_help', 'Appointment confirmations and reminders')}
                    </Text>
                  </div>
                  <Controller
                    name="communication_preferences"
                    control={control}
                    render={({ field }) => (
                      <DesktopSwitch
                        checked={!!((field.value || {}).email_reminders ?? true)}
                        onChange={(checked) => {
                          field.onChange({ ...(field.value || {}), email_reminders: checked })
                        }}
                      />
                    )}
                  />
                </Flex>

                <Flex justify="space-between" align="center">
                  <div>
                    <Text strong>{t('patient.profile.pref_sms_reminders', 'SMS reminders')}</Text>
                    <Text type="secondary" style={{ display: 'block', fontSize: 12 }}>
                      {t('patient.profile.pref_sms_reminders_help', 'Optional SMS updates when available')}
                    </Text>
                  </div>
                  <Controller
                    name="communication_preferences"
                    control={control}
                    render={({ field }) => (
                      <DesktopSwitch
                        checked={!!((field.value || {}).sms_reminders ?? false)}
                        onChange={(checked) => {
                          field.onChange({ ...(field.value || {}), sms_reminders: checked })
                        }}
                      />
                    )}
                  />
                </Flex>
              </Space>
            </DesktopCard>

            <Flex justify="flex-end">
              <DesktopButton type="primary" htmlType="submit" loading={mutation.isPending}>
                {t('patient.profile.save', 'Save changes')}
              </DesktopButton>
            </Flex>
          </Flex>
        </form>
      </Flex>
    </div>
  )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

const PatientProfilePage = ({ patient, errors }: PageProps) => {
  const isMobile = useIsMobile()

  if (isMobile) {
    return <MobilePatientProfile patient={patient} errors={errors} />
  }

  return <DesktopPatientProfile patient={patient} errors={errors} />
}

export default PatientProfilePage
