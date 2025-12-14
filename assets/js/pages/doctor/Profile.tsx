import {
  Button,
  Card,
  Col,
  Row,
  Divider,
  Progress,
  Typography,
  Form,
  Input,
  InputNumber,
  Select,
  Switch,
  Space,
  Flex,
  Tag,
  Tooltip,
  theme,
  message,
  Upload,
  Avatar
} from 'antd'
import {
  IconCheck,
  IconClipboardText,
  IconMapPin,
  IconInfoCircle
} from '@tabler/icons-react'
import { router } from '@inertiajs/react'
import { useMutation } from '@tanstack/react-query'
import { Controller, useForm } from 'react-hook-form'
import { useEffect, useMemo } from 'react'
import { useTranslation } from 'react-i18next'

import type { AppPageProps } from '@/types/app'

const { Title, Text } = Typography
const { TextArea } = Input

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
  profile_image_url: string | null
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

const DoctorProfilePage = ({ doctor, specialties, errors: serverErrors }: PageProps) => {
  const { t } = useTranslation('default')
  const { token } = theme.useToken()
  const normalizedDoctor = useMemo(() => normalizeDoctor(doctor), [doctor])

  const [messageApi, contextHolder] = message.useMessage()

  const {
    control,
    register,
    handleSubmit,
    reset,
    setError,
    setValue,
    formState: { errors: formErrors }
  } = useForm<Profile>({
    defaultValues: normalizedDoctor
  })

  useEffect(() => {
    reset(normalizedDoctor)
  }, [normalizedDoctor, reset])

  useEffect(() => {
    if (!serverErrors) return

    Object.entries(serverErrors).forEach(([field, messages]) => {
      const firstMessage = Array.isArray(messages) ? messages[0] : undefined
      if (!firstMessage) return

      setError(field as keyof Profile, { type: 'server', message: firstMessage })
    })
  }, [serverErrors, setError])

  const mutation = useMutation({
    mutationFn: async (values: Profile) =>
      await new Promise<void>((resolve, reject) => {
        router.post('/dashboard/doctor/profile', { doctor: values }, {
          preserveScroll: true,
          onSuccess: () => {
            messageApi.success(t('doctor.profile.saved', 'Profile saved'))
            resolve()
          },
          onError: () => {
            // Server-side field errors arrive via props; this prevents a generic UX.
            messageApi.error(t('doctor.profile.save_failed', 'Unable to save. Please review the highlighted fields.'))
            resolve()
          }
        })
      })
  })

  const onSubmit = (values: Profile) => mutation.mutate(values)

  const completion = calculateCompletion(normalizedDoctor)

  return (
    <div style={{ padding: 24, maxWidth: 1200, margin: '0 auto' }}>
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
          <Flex justify="space-between" align="flex-start" wrap="wrap" gap="large">
            <div>
              <Title level={2} style={{ margin: 0 }}>{t('doctor.profile.title', 'Doctor profile')}</Title>
              <Text type="secondary" style={{ marginTop: 8, maxWidth: 520, display: 'block' }}>
                {t(
                  'doctor.profile.subtitle',
                  'Polish your public profile so patients instantly understand who you are, what you treat, and how to book you.'
                )}
              </Text>
              <Flex gap="small" style={{ marginTop: 16 }}>
                <Tag color="cyan">
                  {t('doctor.profile.badge_verified', 'Visible in search')}
                </Tag>
                <Tag color="blue">
                  {t('doctor.profile.badge_secure', 'Secure data')}
                </Tag>
              </Flex>
            </div>

            <div style={{ minWidth: 220 }}>
              <Flex vertical gap="small">
                <Flex justify="space-between">
                  <Text strong style={{ fontSize: 14 }}>
                    {t('doctor.profile.completeness', 'Profile completeness')}
                  </Text>
                  <Text type="secondary" style={{ fontSize: 14 }}>
                    {completion}%
                  </Text>
                </Flex>
                <Progress percent={completion} strokeColor={token.colorPrimary} showInfo={false} />
                <Flex gap="small" align="center">
                  <div
                    style={{
                      padding: 4,
                      borderRadius: '50%',
                      background: token.colorFillQuaternary,
                      color: token.colorPrimary,
                      display: 'flex'
                    }}
                  >
                    <IconClipboardText size={14} />
                  </div>
                  <Text type="secondary" style={{ fontSize: 12 }}>
                    {t('doctor.profile.helptext', 'Complete all sections to unlock premium placements.')}
                  </Text>
                </Flex>
              </Flex>
            </div>
          </Flex>
        </Card>

        <Card variant="outlined" style={{ borderRadius: 16 }} styles={{ body: { padding: 24 } }}>
          <Flex vertical gap="middle">
            <Flex gap="small" align="center">
              <div
                style={{
                  padding: 8,
                  borderRadius: '50%',
                  background: token.colorFillQuaternary,
                  color: token.colorPrimary,
                  display: 'flex'
                }}
              >
                <IconMapPin size={20} />
              </div>
              <div>
                <Text strong style={{ display: 'block' }}>{t('doctor.profile.quick_actions', 'Quick actions')}</Text>
                <Text type="secondary" style={{ fontSize: 14 }}>
                  {t('doctor.profile.quick_actions_desc', 'Update your public card in one place and preview the patient-facing layout.')}
                </Text>
              </div>
            </Flex>
            <Divider style={{ margin: '12px 0' }} />
            <Space wrap>
              {['basic', 'professional', 'location', 'expertise'].map((section) => (
                <Button
                  key={section}
                  type="default"
                  shape="round"
                  icon={<IconCheck size={16} />}
                  href={`#${section}`}
                  onClick={(e) => {
                    e.preventDefault();
                    document.getElementById(section)?.scrollIntoView({ behavior: 'smooth' });
                  }}
                  style={{ color: token.colorPrimary, borderColor: token.colorPrimary, backgroundColor: token.colorFillQuaternary }}
                >
                  {t(`doctor.profile.jump_${section}`, section)}
                </Button>
              ))}
            </Space>
          </Flex>
        </Card>

        <form onSubmit={handleSubmit(onSubmit)}>
          <Flex vertical gap="large">
            <Card variant="outlined" style={{ borderRadius: 16 }} id="basic">
              <Flex vertical gap="middle">
                <Title level={4}>{t('doctor.profile.basic', 'Basic info')}</Title>

                <Controller
                  name="profile_image_url"
                  control={control}
                  render={({ field }) => (
                    <div>
                      <div style={{ marginBottom: 8 }}><Text strong>{t('doctor.profile.photo', 'Professional photo')}</Text></div>
                      <Flex gap="middle" align="center" wrap="wrap">
                        <Avatar
                          size={72}
                          src={field.value || undefined}
                          style={{ background: token.colorFillQuaternary, color: token.colorTextSecondary }}
                        >
                          {normalizedDoctor.first_name?.charAt(0) || 'D'}
                        </Avatar>

                        <Upload
                          accept="image/png,image/jpeg,image/webp"
                          showUploadList={false}
                          beforeUpload={(file) => {
                            const okType = ['image/png', 'image/jpeg', 'image/webp'].includes(file.type)
                            if (!okType) {
                              messageApi.error(t('doctor.profile.photo_type', 'Please upload a JPG, PNG, or WebP image'))
                              return Upload.LIST_IGNORE
                            }
                            const okSize = file.size <= 5 * 1024 * 1024
                            if (!okSize) {
                              messageApi.error(t('doctor.profile.photo_size', 'Max file size is 5MB'))
                              return Upload.LIST_IGNORE
                            }
                            return true
                          }}
                          customRequest={async (options) => {
                            try {
                              const formData = new FormData()
                              formData.append('image', options.file as File)

                              const csrf = document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''

                              const res = await fetch('/dashboard/doctor/profile/image', {
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
                                    ? t('doctor.profile.photo_missing', 'No file received. Please try again.')
                                    : code === 'doctor_profile_missing'
                                      ? t('doctor.profile.photo_profile_missing', 'Save your profile first, then upload a photo.')
                                    : code === 'unsupported_type'
                                      ? t('doctor.profile.photo_type', 'Please upload a JPG, PNG, or WebP image')
                                      : code === 'too_large'
                                        ? t('doctor.profile.photo_size', 'Max file size is 5MB')
                                        : code === 'storage_not_configured'
                                          ? t('doctor.profile.photo_storage', 'Storage is not configured. Set Backblaze B2 env vars and restart the server.')
                                          : t('doctor.profile.photo_failed', 'Unable to upload photo. Please try again.')

                                messageApi.error(msg)
                                throw new Error('upload_failed')
                              }

                              if (!data?.profile_image_url) {
                                throw new Error('upload_failed')
                              }

                              setValue('profile_image_url', data.profile_image_url, { shouldDirty: true })
                              messageApi.success(t('doctor.profile.photo_uploaded', 'Photo updated'))
                              options.onSuccess?.(data, options.file as any)
                            } catch (e) {
                              messageApi.error(t('doctor.profile.photo_failed', 'Unable to upload photo. Please try again.'))
                              options.onError?.(e as any)
                            }
                          }}
                        >
                          <Button type="default">
                            {t('doctor.profile.photo_upload', 'Upload photo')}
                          </Button>
                        </Upload>

                        <Text type="secondary" style={{ fontSize: 12, maxWidth: 520 }}>
                          {t('doctor.profile.photo_help', 'Use a clear, front-facing headshot on a neutral background. JPG/PNG/WebP up to 5MB.')}
                        </Text>
                      </Flex>
                    </div>
                  )}
                />
                <Row gutter={16}>
                  <Col xs={24} md={12}>
                    <div style={{ marginBottom: 8 }}><Text strong>First name</Text></div>
                    <Controller
                      name="first_name"
                      control={control}
                      rules={{ required: true }}
                      render={({ field }) => (
                        <Input {...field} status={formErrors.first_name ? 'error' : ''} />
                      )}
                    />
                    {formErrors.first_name?.message && (
                      <Text type="danger">{formErrors.first_name.message}</Text>
                    )}
                  </Col>
                  <Col xs={24} md={12}>
                    <div style={{ marginBottom: 8 }}><Text strong>Last name</Text></div>
                    <Controller
                      name="last_name"
                      control={control}
                      rules={{ required: true }}
                      render={({ field }) => (
                        <Input {...field} status={formErrors.last_name ? 'error' : ''} />
                      )}
                    />
                    {formErrors.last_name?.message && (
                      <Text type="danger">{formErrors.last_name.message}</Text>
                    )}
                  </Col>
                </Row>

                <Row gutter={16}>
                  <Col xs={24} md={12}>
                    <div style={{ marginBottom: 8 }}><Text strong>Title</Text></div>
                    <Controller name="title" control={control} render={({ field }) => <Input {...field} />} />
                  </Col>
                  <Col xs={24} md={12}>
                    <div style={{ marginBottom: 8 }}><Text strong>Academic title</Text></div>
                    <Controller name="academic_title" control={control} render={({ field }) => <Input {...field} />} />
                  </Col>
                </Row>

                <div>
                  <div style={{ marginBottom: 8 }}><Text strong>Profile image URL</Text></div>
                  <Controller name="profile_image_url" control={control} render={({ field }) => <Input {...field} readOnly />} />
                </div>

                <Row gutter={16}>
                  <Col xs={24} md={12}>
                    <div style={{ marginBottom: 8 }}><Text strong>Registration number</Text></div>
                    <Controller name="registration_number" control={control} render={({ field }) => <Input {...field} />} />
                  </Col>
                  <Col xs={24} md={12}>
                    <div style={{ marginBottom: 8 }}><Text strong>Years of experience</Text></div>
                    <Controller
                      name="years_of_experience"
                      control={control}
                      render={({ field }) => (
                        <InputNumber style={{ width: '100%' }} min={0} {...field} />
                      )}
                    />
                  </Col>
                </Row>

                <div>
                  <div style={{ marginBottom: 8 }}><Text strong>Hospital affiliation</Text></div>
                  <Controller name="hospital_affiliation" control={control} render={({ field }) => <Input {...field} />} />
                </div>

                <div>
                  <div style={{ marginBottom: 8 }}><Text strong>Specialty</Text></div>
                  <Controller
                    name="specialty_id"
                    control={control}
                    render={({ field }) => (
                      <Select
                        value={field.value || undefined}
                        onChange={(value) => field.onChange(value || null)}
                        style={{ width: '100%' }}
                        placeholder={t('doctor.profile.select_specialty', 'Select specialty')}
                        options={specialties.map(opt => ({ value: opt.id, label: opt.name }))}
                      />
                    )}
                  />
                  {formErrors.specialty_id?.message && (
                    <Text type="danger">{formErrors.specialty_id.message}</Text>
                  )}
                </div>

                <div>
                  <div style={{ marginBottom: 8 }}><Text strong>Bio (EN)</Text></div>
                  <Controller name="bio" control={control} render={({ field }) => <TextArea autoSize={{ minRows: 4 }} {...field} />} />
                </div>
                <div>
                  <div style={{ marginBottom: 8 }}><Text strong>Bio (EL)</Text></div>
                  <Controller name="bio_el" control={control} render={({ field }) => <TextArea autoSize={{ minRows: 4 }} {...field} />} />
                </div>
              </Flex>
            </Card>

            <Card variant="outlined" style={{ borderRadius: 16 }} id="professional">
              <Flex vertical gap="middle">
                <Title level={4}>{t('doctor.profile.professional', 'Professional')}</Title>

                <Controller
                  control={control}
                  name="board_certifications"
                  render={({ field }) => (
                    <TagInput
                      label={t('doctor.profile.certifications', 'Certifications')}
                      value={field.value}
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
                      value={field.value}
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
                      value={field.value}
                      onChange={field.onChange}
                      options={INSURANCE_OPTIONS}
                      placeholder={t('doctor.profile.insurance_placeholder', 'Choose accepted networks')}
                    />
                  )}
                />
              </Flex>
            </Card>

            <Card variant="outlined" style={{ borderRadius: 16 }} id="location">
              <Flex vertical gap="middle">
                <Title level={4}>{t('doctor.profile.location', 'Location & services')}</Title>

                <Row gutter={16}>
                  <Col xs={24} md={12}>
                    <div style={{ marginBottom: 8 }}><Text strong>Address</Text></div>
                    <Controller name="address" control={control} render={({ field }) => <Input {...field} />} />
                  </Col>
                  <Col xs={24} md={12}>
                    <div style={{ marginBottom: 8 }}><Text strong>City</Text></div>
                    <Controller name="city" control={control} render={({ field }) => <Input {...field} />} />
                  </Col>
                </Row>

                <Card size="small" variant="outlined">
                  <Flex justify="space-between" align="center">
                    <Text>{t('doctor.profile.telemedicine', 'Telemedicine available')}</Text>
                    <Controller
                      name="telemedicine_available"
                      control={control}
                      render={({ field }) => (
                        <Switch checked={field.value} onChange={field.onChange} />
                      )}
                    />
                  </Flex>
                </Card>

                <div>
                  <div style={{ marginBottom: 8 }}><Text strong>Consultation fee (€)</Text></div>
                  <Controller
                    name="consultation_fee"
                    control={control}
                    render={({ field }) => (
                      <InputNumber style={{ width: '100%' }} min={0} step={5} {...field} />
                    )}
                  />
                </div>
              </Flex>
            </Card>

            <Card variant="outlined" style={{ borderRadius: 16 }} id="expertise">
              <Flex vertical gap="middle">
                <Title level={4}>{t('doctor.profile.expertise', 'Expertise')}</Title>

                <Controller
                  control={control}
                  name="sub_specialties"
                  render={({ field }) => (
                    <TagInput
                      label={t('doctor.profile.sub_specialties', 'Sub-specialties')}
                      value={field.value}
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
                      value={field.value}
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
                      value={field.value}
                      onChange={field.onChange}
                      options={CONDITION_OPTIONS}
                    />
                  )}
                />
              </Flex>
            </Card>

            <Flex justify="flex-end">
              <Button type="primary" htmlType="submit" loading={mutation.isPending} disabled={mutation.isPending} size="large">
                {t('doctor.profile.save', 'Save')}
              </Button>
            </Flex>
          </Flex>
        </form>
      </Flex>
    </div>
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

  const selectOptions = Array.from(new Set([...(options || []), ...(value || [])])).map((option) => ({
    value: option,
    label: option
  }))

  return (
    <div>
      <div style={{ marginBottom: 8 }}><Text strong>{label}</Text></div>
      <Select
        mode="tags"
        style={{ width: '100%' }}
        placeholder={placeholder}
        value={value || []}
        onChange={onChange}
        options={selectOptions}
        tokenSeparators={[',']}
      />
    </div>
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

const normalizeDoctor = (doctor: any): Profile => {
  // Inertia may camelize keys; accept both and emit ONLY snake_case keys
  // so react-hook-form doesn't keep/submit duplicate camelCase fields.
  const get = <T,>(snakeKey: string, camelKey: string, fallback: T): T => {
    const snakeVal = doctor?.[snakeKey]
    if (snakeVal !== undefined && snakeVal !== null) return snakeVal as T

    const camelVal = doctor?.[camelKey]
    if (camelVal !== undefined && camelVal !== null) return camelVal as T

    return fallback
  }

  return {
    id: get('id', 'id', ''),
    first_name: get('first_name', 'firstName', ''),
    last_name: get('last_name', 'lastName', ''),
    title: get('title', 'title', ''),
    profile_image_url: get('profile_image_url', 'profileImageUrl', ''),
    academic_title: get('academic_title', 'academicTitle', ''),
    hospital_affiliation: get('hospital_affiliation', 'hospitalAffiliation', ''),
    registration_number: get('registration_number', 'registrationNumber', ''),
    years_of_experience: get('years_of_experience', 'yearsOfExperience', null),
    specialty_id: get('specialty_id', 'specialtyId', null),
    bio: get('bio', 'bio', ''),
    bio_el: get('bio_el', 'bioEl', ''),
    address: get('address', 'address', ''),
    city: get('city', 'city', ''),
    telemedicine_available: get('telemedicine_available', 'telemedicineAvailable', false),
    consultation_fee: get('consultation_fee', 'consultationFee', null),
    board_certifications: get('board_certifications', 'boardCertifications', []),
    languages: get('languages', 'languages', []),
    insurance_networks: get('insurance_networks', 'insuranceNetworks', []),
    sub_specialties: get('sub_specialties', 'subSpecialties', []),
    clinical_procedures: get('clinical_procedures', 'clinicalProcedures', []),
    conditions_treated: get('conditions_treated', 'conditionsTreated', [])
  }
}

