import { useEffect, useMemo } from 'react'
import {
  Avatar,
  Button,
  Card,
  Col,
  DatePicker,
  Divider,
  Flex,
  Input,
  Row,
  Space,
  Switch,
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

import type { AppPageProps } from '@/types/app'

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
  // Inertia camelizes keys; accept both and emit ONLY snake_case keys
  // so react-hook-form doesn't keep/submit duplicate camelCase fields.
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

const PatientProfilePage = ({ patient, errors: serverErrors }: PageProps) => {
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
        <Card
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
        </Card>

        <form onSubmit={handleSubmit(onSubmit)}>
          <Flex vertical gap="large">
            <Card variant="outlined" style={{ borderRadius: 16 }}>
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
                              const code = data?.error
                              const msg =
                                code === 'missing_file'
                                  ? t('patient.profile.photo_missing', 'No file received. Please try again.')
                                  : code === 'patient_profile_missing'
                                    ? t(
                                        'patient.profile.photo_profile_missing',
                                        'Save your profile first, then upload a photo.'
                                      )
                                    : code === 'unsupported_type'
                                      ? t('patient.profile.photo_type', 'Please upload a JPG, PNG, or WebP image')
                                      : code === 'too_large'
                                        ? t('patient.profile.photo_size', 'Max file size is 5MB')
                                        : code === 'storage_not_configured'
                                          ? t(
                                              'patient.profile.photo_storage',
                                              'Storage is not configured. Configure storage and restart the server.'
                                            )
                                          : t('patient.profile.photo_failed', 'Unable to upload photo. Please try again.')

                              messageApi.error(msg)
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
                        <Button type="default">{t('patient.profile.photo_upload', 'Upload photo')}</Button>
                      </Upload>

                      <Text type="secondary" style={{ fontSize: 12, maxWidth: 520 }}>
                        {t(
                          'patient.profile.photo_help',
                          'Use a clear photo. JPG/PNG/WebP up to 5MB.'
                        )}
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
                      <Input {...field} status={formErrors.first_name ? 'error' : ''} />
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
                      <Input {...field} status={formErrors.last_name ? 'error' : ''} />
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
                      <Input {...field} placeholder="+30..." status={formErrors.phone ? 'error' : ''} />
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
                      <Input {...field} placeholder={t('patient.profile.emergency_placeholder', 'Name + phone')} />
                    )}
                  />
                </Col>
              </Row>
            </Card>

            <Card variant="outlined" style={{ borderRadius: 16 }}>
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
                      <Input {...field} placeholder="en / el" />
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
                    render={({ field }) => <Input {...field} placeholder="Europe/Athens" />}
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
                      <Switch
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
                      <Switch
                        checked={!!((field.value || {}).sms_reminders ?? false)}
                        onChange={(checked) => {
                          field.onChange({ ...(field.value || {}), sms_reminders: checked })
                        }}
                      />
                    )}
                  />
                </Flex>
              </Space>
            </Card>

            <Flex justify="flex-end">
              <Button type="primary" htmlType="submit" loading={mutation.isPending}>
                {t('patient.profile.save', 'Save changes')}
              </Button>
            </Flex>
          </Flex>
        </form>
      </Flex>
    </div>
  )
}

export default PatientProfilePage
