import React, { useMemo, useState } from 'react'
import {
  Button as DesktopButton,
  Card as DesktopCard,
  Col,
  Row,
  Divider,
  Typography,
  Tabs as DesktopTabs,
  Tag,
  Empty as DesktopEmpty,
  Flex,
  theme,
  Statistic,
  Alert,
  message,
  Popconfirm,
  Modal,
  Input,
  Slider as DesktopSlider,
  List as DesktopList,
  Avatar,
  Space
} from 'antd'
import { HeartOutlined } from '@ant-design/icons'
import {
  IconCalendar,
  IconCalendarEvent,
  IconClock,
  IconFileText,
  IconUser,
  IconVideo,
  IconMapPin,
  IconInfoCircle,
  IconStar
} from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import { format } from 'date-fns'
import { enUS, el } from 'date-fns/locale'
import { router } from '@inertiajs/react'
import { useIsMobile } from '@/lib/device'

import type { AppPageProps } from '@/types/app'

// Mobile imports
import {
  Button as MobileButton,
  Card as MobileCard,
  Tabs as MobileTabs,
  Tag as MobileTag,
  Empty,
  Toast,
  Dialog,
  TextArea as MobileTextArea,
  Slider as MobileSlider
} from 'antd-mobile'
import { CalendarOutline, ClockCircleOutline, LocationOutline, VideoOutline } from 'antd-mobile-icons'

const { Title, Text } = Typography
const { useToken } = theme

type Appointment = {
  id: string
  doctor: {
    firstName: string
    lastName: string
    specialty?: string | null
    avatarUrl?: string | null
  }
  startsAt: string
  status: string
  consultationMode?: 'in_person' | 'video' | 'telemedicine' | string
  pendingExpiresAt?: string | null
  rescheduledFromAppointmentId?: string | null
  appreciated?: boolean
  hasExperienceSubmission?: boolean
}

type MyDoctor = {
  id: string
  firstName: string
  lastName: string
  specialty?: string
  profileImageUrl?: string
  rating?: number
  visitCount: number
  lastVisit: string | null
  firstVisit: string | null
  hasContext: boolean
  tags?: string[]
}

type PageProps = AppPageProps<{
  upcomingAppointments?: Appointment[]
  pastAppointments?: Appointment[]
  patient?: {
    firstName: string
    lastName: string
  }
  stats?: {
    upcoming: number
    completed: number
    cancelled: number
  }
  myDoctors?: MyDoctor[]
  activeTab?: 'dashboard' | 'doctors'
}>

const getCsrfToken = () => document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''

const getStatusColor = (status: string) => {
  switch (status) {
    case 'confirmed':
      return 'success'
    case 'pending':
    case 'held':
      return 'warning'
    case 'cancelled':
    case 'no_show':
      return 'danger'
    case 'completed':
      return 'default'
    default:
      return 'default'
  }
}

const EXPERIENCE_SLIDERS = [
  { key: 'communication_style', label: 'Communication Style', start: 'Listens quietly', end: 'Very talkative' },
  { key: 'explanation_style', label: 'Explanation Style', start: 'Straight to the point', end: 'Very detailed' },
  { key: 'personality_tone', label: 'Personality Tone', start: 'Serious & professional', end: 'Warm & friendly' },
  { key: 'pace', label: 'Pace', start: 'Efficient & fast', end: 'Takes extra time' },
  { key: 'appointment_timing', label: 'Appointment Timing', start: 'Exactly on time', end: 'Flexible with time' },
  { key: 'consultation_style', label: 'Consultation Style', start: 'Directive (tells you what to do)', end: 'Collaborative (discusses options)' }
] as const

// =============================================================================
// MY DOCTORS LIST (MVP - Desktop Only)
// =============================================================================

function MyDoctorsList({ doctors }: { doctors: MyDoctor[] }) {
  const { t, i18n } = useTranslation('default')
  const dateLocale = DATE_LOCALES[i18n.language] || enUS

  return (
    <DesktopCard
      title={<Title level={3}>{t('My Doctors')}</Title>}
      bordered={false}
      style={{ borderRadius: 16, boxShadow: '0 1px 6px rgba(0,0,0,0.04)' }}
    >
      {doctors.length === 0 ? (
        <DesktopEmpty description={t('No doctors yet')} />
      ) : (
        <DesktopList
          itemLayout="horizontal"
          dataSource={doctors}
          renderItem={(doctor) => (
            <DesktopList.Item>
              <DesktopList.Item.Meta
                avatar={
                  doctor.profileImageUrl ? (
                    <Avatar size={48} src={doctor.profileImageUrl} />
                  ) : (
                    <Avatar size={48} style={{ backgroundColor: '#0d9488' }}>
                      {doctor.firstName?.[0] || 'D'}
                    </Avatar>
                  )
                }
                title={
                  <Space>
                    <span style={{ fontWeight: 600 }}>
                      Dr. {doctor.firstName} {doctor.lastName}
                    </span>
                    {doctor.rating && (
                      <Tag icon={<IconStar size={12} />} color="gold">
                        {doctor.rating.toFixed(1)}
                      </Tag>
                    )}
                  </Space>
                }
                description={
                  <Space direction="vertical" size={0}>
                    {doctor.specialty && (
                      <Text type="secondary">{doctor.specialty}</Text>
                    )}
                    <Space split="|" size="small">
                      <Text type="secondary">
                        {t('Seen {{count}} times', { count: doctor.visitCount })}
                      </Text>
                      {doctor.lastVisit && (
                        <Text type="secondary">
                          {t('Last visit')}: {format(new Date(doctor.lastVisit), 'P', { locale: dateLocale })}
                        </Text>
                      )}
                    </Space>
                  </Space>
                }
              />
            </DesktopList.Item>
          )}
        />
      )}
    </DesktopCard>
  )
}

// =============================================================================
// MOBILE PATIENT DASHBOARD
// =============================================================================

const DATE_LOCALES: Record<string, any> = { en: enUS, el }

function MobilePatientDashboard({ upcomingAppointments = [], pastAppointments = [], patient, stats }: Omit<PageProps, 'app' | 'auth'>) {
  const { t, i18n } = useTranslation('default')
  const dateLocale = DATE_LOCALES[i18n.language] || enUS
  const [upcoming, setUpcoming] = useState(upcomingAppointments)
  const [past, setPast] = useState(pastAppointments)
  const [loadingKey, setLoadingKey] = useState<string | null>(null)
  const [profileModalOpen, setProfileModalOpen] = useState(false)
  const [selectedProfileId, setSelectedProfileId] = useState<string | null>(null)
  const patientName = patient?.firstName || t('dashboard.patient_fallback', 'there')

  const handleApprove = async (id: string) => {
    setLoadingKey(`approve:${id}`)
    try {
      const res = await fetch(`/appointments/${id}/approve_reschedule`, {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() }
      })
      if (!res.ok) throw new Error('approve_failed')
      Toast.show({ icon: 'success', content: t('Reschedule approved') })
      window.location.reload()
    } catch (err) {
      Toast.show({ icon: 'fail', content: t('Something went wrong') })
      setLoadingKey(null)
    }
  }

  const handleReject = async (id: string) => {
    setLoadingKey(`reject:${id}`)
    try {
      const body = new URLSearchParams({ reason: t('You declined this reschedule') })
      const res = await fetch(`/appointments/${id}/reject_reschedule`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() },
        body: body.toString()
      })
      if (!res.ok) throw new Error('reject_failed')
      Toast.show({ icon: 'success', content: t('Reschedule rejected') })
      setUpcoming((prev) => prev.filter((item) => item.id !== id))
    } catch (err) {
      Toast.show({ icon: 'fail', content: t('Unable to reject') })
      setLoadingKey(null)
    }
  }

  const handleCancel = async (appt: Appointment) => {
    const isPending = appt.status === 'pending'
    const startsAt = new Date(appt.startsAt)
    const dateStr = format(startsAt, 'EEE MMM d, h:mm a')
    const doctorName = `Dr. ${appt.doctor.firstName} ${appt.doctor.lastName}`

    const title = isPending ? t('Withdraw this request?') : t('Cancel this appointment?')
    const content = isPending
      ? t("You'll remove your request for {{date}} with {{doctor}}.", { date: dateStr, doctor: doctorName })
      : t('This will notify the doctor and free the time slot.')

    const result = await Dialog.confirm({
      title,
      content,
      confirmText: isPending ? t('Withdraw request') : t('Cancel appointment'),
      cancelText: isPending ? t('Keep request') : t('Keep appointment')
    })
    if (!result) return

    setLoadingKey(`cancel:${appt.id}`)
    try {
      const body = new URLSearchParams({ reason: isPending ? t('Withdrawn by patient') : t('Cancelled by patient') })
      const res = await fetch(`/appointments/${appt.id}/cancel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() },
        body: body.toString()
      })
      if (!res.ok) throw new Error('cancel_failed')
      Toast.show({ icon: 'success', content: isPending ? t('Request withdrawn') : t('Appointment cancelled') })
      setUpcoming((prev) => prev.filter((item) => item.id !== appt.id))
    } catch (err) {
      Toast.show({ icon: 'fail', content: t('Unable to cancel') })
      setLoadingKey(null)
    }
  }

  const handleProfileSubmit = async (data: Record<string, number>) => {
    if (!selectedProfileId) return
    setLoadingKey(`profile:${selectedProfileId}`)

    try {
      const res = await fetch(`/appointments/${selectedProfileId}/experience_submission`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'x-csrf-token': getCsrfToken()
        },
        body: JSON.stringify(data)
      })

      if (!res.ok) throw new Error('profile_failed')

      Toast.show({ icon: 'success', content: t('Thank you for helping others!') })
      setPast((prev) => prev.map((appt) => (appt.id === selectedProfileId ? { ...appt, hasExperienceSubmission: true } : appt)))
      setProfileModalOpen(false)
      setSelectedProfileId(null)
    } catch (err) {
      Toast.show({ icon: 'fail', content: t('Unable to submit') })
    } finally {
      setLoadingKey(null)
    }
  }

  const handleAppreciate = async (id: string) => {
    setLoadingKey(`appreciate:${id}`)
    try {
      const res = await fetch(`/appointments/${id}/appreciate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() },
        body: 'note_text='
      })
      if (res.status === 409) {
        Toast.show({ content: t('Already appreciated') })
      } else if (!res.ok) {
        throw new Error('appreciation_failed')
      } else {
        Toast.show({ icon: 'success', content: t('Thank you!') })
      }
      setPast((prev) => prev.map((appt) => (appt.id === id ? { ...appt, appreciated: true } : appt)))
    } catch (err) {
      Toast.show({ icon: 'fail', content: t('Unable to send') })
    } finally {
      setLoadingKey(null)
    }
  }

  const renderMobileAppointment = (appt: Appointment, isUpcoming: boolean) => {
    const mode = appt.consultationMode || 'in_person'
    const isVideo = mode === 'video' || mode === 'telemedicine'
    const isReschedulePending = appt.status === 'pending' && Boolean(appt.rescheduledFromAppointmentId)
    const isPendingApproval = appt.status === 'pending'

    return (
      <MobileCard
        key={appt.id}
        style={{ marginBottom: 12, borderRadius: 12 }}
        onClick={() => router.visit(`/appointments/${appt.id}`)}
      >
        <div style={{ display: 'flex', gap: 12 }}>
          {/* Avatar */}
          <div style={{
            width: 48,
            height: 48,
            borderRadius: '50%',
            backgroundColor: '#f1f5f9',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
            overflow: 'hidden'
          }}>
            {appt.doctor.avatarUrl ? (
              <img src={appt.doctor.avatarUrl} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
            ) : (
              <IconUser size={24} color="#64748b" />
            )}
          </div>

          {/* Info */}
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 2 }}>
              <span style={{ fontWeight: 600, fontSize: 15 }}>
                Dr. {appt.doctor.firstName} {appt.doctor.lastName}
              </span>
              <MobileTag
                color={appt.status === 'confirmed' ? 'success' : appt.status === 'pending' ? 'warning' : appt.status === 'cancelled' ? 'danger' : 'default'}
                fill="outline"
                style={{ fontSize: 10 }}
              >
                {appt.status === 'pending' ? t('Pending') : appt.status === 'confirmed' ? t('Confirmed') : t(appt.status)}
              </MobileTag>
            </div>
            <div style={{ color: '#666', fontSize: 13, marginBottom: 6 }}>
              {appt.doctor.specialty || t('General practice')}
            </div>
            {/* Date/Time more prominent */}
            <div style={{ fontWeight: 500, fontSize: 14, color: isPendingApproval ? '#d97706' : '#1f2937', marginBottom: 4 }}>
              {format(new Date(appt.startsAt), 'EEE, MMM d', { locale: dateLocale })} • {format(new Date(appt.startsAt), 'h:mm a', { locale: dateLocale })}
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: '#0d9488' }}>
              {isVideo ? <VideoOutline fontSize={12} /> : <LocationOutline fontSize={12} />}
              {isVideo ? t('Video Visit') : t('In-person')}
            </div>
            {isPendingApproval && !isReschedulePending && (
              <div style={{ fontSize: 11, color: '#92400e', marginTop: 4 }}>
                {t('Typically confirms within 2–24h')}
              </div>
            )}
          </div>

          {/* Mode Icon */}
          <div style={{ color: '#0d9488' }}>
            {isVideo ? <VideoOutline fontSize={20} /> : <LocationOutline fontSize={20} />}
          </div>
        </div>

        {/* Reschedule pending actions */}
        {isUpcoming && isReschedulePending && (
          <div style={{ marginTop: 12, padding: 12, backgroundColor: '#fffbeb', borderRadius: 8 }}>
            <div style={{ fontSize: 13, color: '#92400e', marginBottom: 8 }}>
              ⚠️ {t('Review this rescheduled time')}
            </div>
            <div style={{ display: 'flex', gap: 8 }} onClick={(e) => e.stopPropagation()}>
              <MobileButton
                size="small"
                color="primary"
                loading={loadingKey === `approve:${appt.id}`}
                onClick={() => handleApprove(appt.id)}
              >
                {t('Approve')}
              </MobileButton>
              <MobileButton
                size="small"
                loading={loadingKey === `reject:${appt.id}`}
                onClick={() => handleReject(appt.id)}
              >
                {t('Reject')}
              </MobileButton>
            </div>
          </div>
        )}

        {/* Pending cancel action */}
        {isUpcoming && isPendingApproval && !isReschedulePending && (
          <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8 }} onClick={(e) => e.stopPropagation()}>
            <MobileButton
              size="small"
              color="primary"
              fill="outline"
            >
              {t('Change requested time')}
            </MobileButton>
            <MobileButton
              size="small"
              color="danger"
              fill="outline"
              loading={loadingKey === `cancel:${appt.id}`}
              onClick={() => handleCancel(appt)}
            >
              {t('Withdraw request')}
            </MobileButton>
          </div>
        )}

        {/* Actions for past completed */}
        {!isUpcoming && appt.status === 'completed' && (
          <div style={{ marginTop: 12, display: 'flex', gap: 8 }} onClick={(e) => e.stopPropagation()}>
            {!appt.hasExperienceSubmission && (
              <MobileButton
                size="small"
                color="primary"
                fill="outline"
                loading={loadingKey === `profile:${appt.id}`}
                onClick={() => {
                  setSelectedProfileId(appt.id)
                  setProfileModalOpen(true)
                }}
              >
                Profile Doctor
              </MobileButton>
            )}
            {!appt.appreciated && (
              <MobileButton
                size="small"
                color="danger"
                loading={loadingKey === `appreciate:${appt.id}`}
                onClick={() => handleAppreciate(appt.id)}
              >
                ♥ Appreciate
              </MobileButton>
            )}
          </div>
        )}
      </MobileCard>
    )
  }

  return (
    <div style={{ padding: 16, paddingBottom: 100 }}>
      {/* Header */}
      <div style={{ marginBottom: 20 }}>
        <p style={{ color: '#666', fontSize: 12, textTransform: 'uppercase', margin: '0 0 4px' }}>
          {t('Dashboard')}
        </p>
        <h2 style={{ fontSize: 22, fontWeight: 700, margin: '0 0 4px' }}>
          {t('Hello, {{name}}', { name: patientName })}
        </h2>
        <p style={{ color: '#666', margin: 0, fontSize: 14 }}>
          {t('Manage your health journey')}
        </p>
      </div>

      {/* Stats */}
      {stats && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, marginBottom: 20 }}>
          <div style={{ backgroundColor: '#fff', borderRadius: 10, padding: 12, textAlign: 'center', border: '1px solid #f0f0f0' }}>
            <div style={{ fontSize: 22, fontWeight: 700, color: '#0d9488' }}>{stats.upcoming}</div>
            <div style={{ fontSize: 11, color: '#888' }}>{t('Upcoming')}</div>
          </div>
          <div style={{ backgroundColor: '#fff', borderRadius: 10, padding: 12, textAlign: 'center', border: '1px solid #f0f0f0' }}>
            <div style={{ fontSize: 22, fontWeight: 700 }}>{stats.completed}</div>
            <div style={{ fontSize: 11, color: '#888' }}>{t('Completed')}</div>
          </div>
          <div style={{ backgroundColor: '#fff', borderRadius: 10, padding: 12, textAlign: 'center', border: '1px solid #f0f0f0' }}>
            <div style={{ fontSize: 22, fontWeight: 700, color: '#dc2626' }}>{stats.cancelled}</div>
            <div style={{ fontSize: 11, color: '#888' }}>{t('Cancelled')}</div>
          </div>
        </div>
      )}

      {/* Book Button */}
      <MobileButton
        block
        color="primary"
        size="large"
        onClick={() => router.visit('/search')}
        style={{ marginBottom: 20, '--border-radius': '10px' } as React.CSSProperties}
      >
        <CalendarOutline style={{ marginRight: 8 }} />
        {t('Book Appointment')}
      </MobileButton>

      {/* Appointments Tabs */}
      <MobileTabs>
        <MobileTabs.Tab title={`${t('Upcoming')} (${upcoming.length})`} key="upcoming">
          <div style={{ paddingTop: 12 }}>
            {upcoming.length > 0 ? (
              upcoming.map((appt) => renderMobileAppointment(appt, true))
            ) : (
              <Empty description={t('No upcoming appointments')} />
            )}
          </div>
        </MobileTabs.Tab>
        <MobileTabs.Tab title={`${t('Past')} (${past.length})`} key="past">
          <div style={{ paddingTop: 12 }}>
            {past.length > 0 ? (
              past.map((appt) => renderMobileAppointment(appt, false))
            ) : (
              <Empty description={t('No past appointments')} />
            )}
          </div>
        </MobileTabs.Tab>
      </MobileTabs>

      <ExperienceProfileModal
        open={profileModalOpen}
        onClose={() => setProfileModalOpen(false)}
        onSubmit={handleProfileSubmit}
        loading={loadingKey === `profile:${selectedProfileId}`}
      />
    </div>
  )
}

// =============================================================================
// DESKTOP PATIENT DASHBOARD (Original)
// =============================================================================

function DesktopPatientDashboard({ upcomingAppointments = [], pastAppointments = [], patient, stats }: Omit<PageProps, 'app' | 'auth'>) {
  const { t, i18n } = useTranslation('default')
  const { token } = useToken()
  const dateLocale = DATE_LOCALES[i18n.language] || enUS
  const [messageApi, contextHolder] = message.useMessage()
  const [upcoming, setUpcoming] = useState(upcomingAppointments)
  const [past, setPast] = useState(pastAppointments)
  const [loadingKey, setLoadingKey] = useState<string | null>(null)
  const patientName = patient?.firstName || t('dashboard.patient_fallback', 'there')

  // Appreciation State
  const [appreciationModalOpen, setAppreciationModalOpen] = useState(false)
  const [selectedAppointmentId, setSelectedAppointmentId] = useState<string | null>(null)
  const [appreciationNote, setAppreciationNote] = useState('')
  const [profileModalOpen, setProfileModalOpen] = useState(false)
  const [selectedProfileId, setSelectedProfileId] = useState<string | null>(null)

  const openAppreciationModal = (id: string) => {
    setSelectedAppointmentId(id)
    setAppreciationModalOpen(true)
  }

  const handleAppreciateSubmit = async () => {
    if (!selectedAppointmentId) return
    setLoadingKey(`appreciate:${selectedAppointmentId}`)

    try {
      const body = new URLSearchParams({ note_text: appreciationNote })
      const res = await fetch(`/appointments/${selectedAppointmentId}/appreciate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() },
        body: body.toString()
      })

      if (res.status === 409) {
        setPast((prev) => prev.map((appt) => (appt.id === selectedAppointmentId ? { ...appt, appreciated: true } : appt)))
        setAppreciationModalOpen(false)
        setAppreciationNote('')
        setSelectedAppointmentId(null)
        messageApi.info(t('dashboard.already_appreciated', 'You already appreciated this appointment'))
        return
      }

      if (!res.ok) throw new Error('appreciation_failed')

      setPast((prev) => prev.map((appt) => (appt.id === selectedAppointmentId ? { ...appt, appreciated: true } : appt)))
      setAppreciationModalOpen(false)
      setAppreciationNote('')
      setSelectedAppointmentId(null)
      messageApi.success(t('dashboard.appreciation_sent', 'Appreciation sent!'))
    } catch (err) {
      messageApi.error(t('dashboard.appreciation_error', 'Unable to submit appreciation. Please try again.'))
    } finally {
      setLoadingKey(null)
    }
  }

  const handleProfileSubmit = async (data: Record<string, number>) => {
    if (!selectedProfileId) return
    setLoadingKey(`profile:${selectedProfileId}`)

    try {
      const res = await fetch(`/appointments/${selectedProfileId}/experience_submission`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'x-csrf-token': getCsrfToken()
        },
        body: JSON.stringify(data)
      })

      if (!res.ok) throw new Error('profile_failed')

      messageApi.success(t('Thank you for helping others!'))
      setPast((prev) => prev.map((appt) => (appt.id === selectedProfileId ? { ...appt, hasExperienceSubmission: true } : appt)))
      setProfileModalOpen(false)
      setSelectedProfileId(null)
    } catch (err) {
      messageApi.error(t('Unable to submit profile. Please try again.'))
    } finally {
      setLoadingKey(null)
    }
  }

  const handleApprove = async (id: string) => {
    setLoadingKey(`approve:${id}`)
    try {
      const res = await fetch(`/appointments/${id}/approve_reschedule`, {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() }
      })
      if (!res.ok) throw new Error('approve_failed')
      messageApi.success(t('dashboard.approve_success', 'Reschedule approved'))
      window.location.reload()
    } catch (err) {
      messageApi.error(t('dashboard.approve_error', 'Something went wrong. Please try again.'))
      setLoadingKey(null)
    }
  }

  const handleReject = async (id: string) => {
    setLoadingKey(`reject:${id}`)
    try {
      const body = new URLSearchParams({ reason: t('You declined this reschedule') })
      const res = await fetch(`/appointments/${id}/reject_reschedule`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() },
        body: body.toString()
      })
      if (!res.ok) throw new Error('reject_failed')
      messageApi.success(t('dashboard.reject_success', 'Reschedule rejected'))
      setUpcoming((prev) => prev.filter((item) => item.id !== id))
    } catch (err) {
      messageApi.error(t('dashboard.reject_error', 'Unable to reject right now. Please try again.'))
      setLoadingKey(null)
    }
  }

  const handleCancel = async (id: string) => {
    setLoadingKey(`cancel:${id}`)
    try {
      const body = new URLSearchParams({ reason: t('Cancelled by patient') })
      const res = await fetch(`/appointments/${id}/cancel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() },
        body: body.toString()
      })
      if (!res.ok) throw new Error('cancel_failed')
      messageApi.success(t('dashboard.cancel_success', 'Appointment cancelled'))
      setUpcoming((prev) => prev.filter((item) => item.id !== id))
    } catch (err) {
      messageApi.error(t('dashboard.cancel_error', 'Unable to cancel right now. Please try again.'))
      setLoadingKey(null)
    }
  }

  const renderAppointment = (appt: Appointment, isUpcoming: boolean) => {
    const mode = appt.consultationMode || 'in_person'
    const isVideo = mode === 'video' || mode === 'telemedicine'
    const doctorSpecialty = appt.doctor.specialty || t('General practice')
    const isPendingApproval = appt.status === 'pending'
    const isReschedulePending = isPendingApproval && Boolean(appt.rescheduledFromAppointmentId)
    const dateColor = isReschedulePending ? token.colorWarningText : token.colorText

    return (
      <DesktopCard
        key={appt.id}
        style={{ width: '100%', marginBottom: 16, borderRadius: 14, borderColor: token.colorBorderSecondary, boxShadow: '0 8px 24px rgba(15, 23, 42, 0.04)', background: token.colorBgContainer }}
        styles={{ body: { padding: 22 } }}
      >
        <Row gutter={[16, 16]} align="middle">
          <Col xs={24} sm={16}>
            <Flex gap="middle" align="start">
              <div style={{ width: 48, height: 48, borderRadius: '50%', backgroundColor: '#f1f5f9', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#64748b', flexShrink: 0 }}>
                {appt.doctor.avatarUrl ? (
                  <img src={appt.doctor.avatarUrl} alt="Doctor" style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }} />
                ) : (
                  <IconUser size={24} />
                )}
              </div>
              <div>
                <Flex align="center" gap="small" style={{ marginBottom: 4 }}>
                  <Text strong style={{ fontSize: 16 }}>Dr. {appt.doctor.firstName} {appt.doctor.lastName}</Text>
                  <Tag color={appt.status === 'confirmed' ? 'green' : appt.status === 'pending' ? 'orange' : appt.status === 'cancelled' ? 'red' : 'default'}>
                    {appt.status === 'pending' ? t('Pending') : appt.status === 'confirmed' ? t('Confirmed') : t(appt.status)}
                  </Tag>
                </Flex>
                <Text type="secondary" style={{ display: 'block' }}>{doctorSpecialty}</Text>
                <Flex gap="small" style={{ marginTop: 8 }} align="center">
                  {isVideo ? <IconVideo size={14} color="#0d9488" /> : <IconMapPin size={14} color="#0d9488" />}
                  <Text style={{ fontSize: 13, color: '#0d9488' }}>{isVideo ? t('Video Visit') : t('In-person')}</Text>
                </Flex>
                {isPendingApproval && !isReschedulePending && (
                  <Text type="secondary" style={{ fontSize: 12, marginTop: 4, display: 'block' }}>
                    {t('Typically confirms within 2–24h')}
                  </Text>
                )}
              </div>
            </Flex>
          </Col>
          <Col xs={24} sm={8}>
            <Flex vertical align="end" gap="small" style={{ textAlign: 'right' }}>
              <Text strong style={{ fontSize: 15, color: dateColor }}>{format(new Date(appt.startsAt), 'EEE, MMM d, yyyy', { locale: dateLocale })}</Text>
              <Text style={{ color: dateColor }}>{format(new Date(appt.startsAt), 'h:mm a', { locale: dateLocale })}</Text>
            </Flex>
          </Col>
        </Row>

        {isUpcoming && (
          <>
            <Divider style={{ margin: '16px 0' }} />
            {isReschedulePending && (
              <Alert type="warning" showIcon icon={<IconInfoCircle size={16} color={token.colorWarningText} />} message={t('Review this rescheduled time')} description={t('Confirm if the new time works or choose to reject it.')} style={{ marginBottom: 12, background: token.colorWarningBg, borderColor: token.colorWarningBorder, borderRadius: 10 }} />
            )}
            <Flex justify="flex-end" gap="small" wrap>
              {isReschedulePending ? (
                <>
                  <DesktopButton type="primary" onClick={() => handleApprove(appt.id)} loading={loadingKey === `approve:${appt.id}`}>{t('Approve')}</DesktopButton>
                  <Popconfirm title={t('Reject this rescheduled time?')} description={t('This booking will be cancelled if you reject.')} okText={t('Yes')} cancelText={t('No')} onConfirm={() => handleReject(appt.id)}>
                    <DesktopButton loading={loadingKey === `reject:${appt.id}`}>{t('Reject')}</DesktopButton>
                  </Popconfirm>
                </>
              ) : (
                <>
                  {isPendingApproval ? (
                    <Flex align="center" gap="small" wrap>
                      <div className="loader" />
                      <Text type="secondary">{t('Waiting for your doctor to confirm')}</Text>
                      <DesktopButton>{t('Change requested time')}</DesktopButton>
                      <Popconfirm
                        title={t('Withdraw this request?')}
                        description={t("You'll remove your request for {{date}} with Dr. {{doctor}}.", {
                          date: format(new Date(appt.startsAt), 'EEE MMM d, h:mm a'),
                          doctor: `${appt.doctor.firstName} ${appt.doctor.lastName}`
                        })}
                        okText={t('Withdraw request')}
                        cancelText={t('Keep request')}
                        okButtonProps={{ danger: true }}
                        onConfirm={() => handleCancel(appt.id)}
                      >
                        <DesktopButton loading={loadingKey === `cancel:${appt.id}`} danger>{t('Withdraw request')}</DesktopButton>
                      </Popconfirm>
                    </Flex>
                  ) : (
                    <>
                      {isVideo && <DesktopButton type="primary" icon={<IconVideo size={16} />}>{t('Join Call')}</DesktopButton>}
                      <DesktopButton>{t('Reschedule')}</DesktopButton>
                      <Popconfirm
                        title={t('Cancel this appointment?')}
                        description={t('This will notify the doctor and free the time slot.')}
                        okText={t('Cancel appointment')}
                        cancelText={t('Keep appointment')}
                        okButtonProps={{ danger: true }}
                        onConfirm={() => handleCancel(appt.id)}
                      >
                        <DesktopButton danger>{t('Cancel appointment')}</DesktopButton>
                      </Popconfirm>
                    </>
                  )}
                </>
              )}
            </Flex>
          </>
        )}

        {!isUpcoming && appt.status === 'completed' && (
          <>
            <Divider style={{ margin: '16px 0' }} />
            <Flex justify="flex-end" gap="small">
              {!appt.hasExperienceSubmission && (
                <DesktopButton
                  onClick={() => {
                    setSelectedProfileId(appt.id)
                    setProfileModalOpen(true)
                  }}
                  loading={loadingKey === `profile:${appt.id}`}
                >
                  Profile Doctor
                </DesktopButton>
              )}
              {!appt.appreciated && (
                <DesktopButton type="primary" icon={<HeartOutlined />} style={{ backgroundColor: token.colorError, borderColor: token.colorError }} onClick={() => openAppreciationModal(appt.id)}>Appreciate Doctor</DesktopButton>
              )}
            </Flex>
          </>
        )}
      </DesktopCard>
    )
  }

  const items = useMemo(() => ([
    { key: 'upcoming', label: t('Upcoming'), children: upcoming.length > 0 ? upcoming.map((appt) => renderAppointment(appt, true)) : <DesktopEmpty image={DesktopEmpty.PRESENTED_IMAGE_SIMPLE} description={t('No upcoming appointments')}><DesktopButton type="primary" href="/search">{t('Book a new appointment')}</DesktopButton></DesktopEmpty> },
    { key: 'past', label: t('Past'), children: past.length > 0 ? past.map((appt) => renderAppointment(appt, false)) : <DesktopEmpty description={t('No past appointments')} /> }
  ]), [upcoming, past, renderAppointment, t])

  return (
    <>
      {contextHolder}
      <div style={{ minHeight: '100vh', background: token.colorBgLayout }}>
        <div style={{ maxWidth: 1200, margin: '0 auto', padding: '24px' }}>
          <DesktopCard bordered={false} style={{ borderRadius: 16, background: `linear-gradient(120deg, ${token.colorPrimaryBg} 0%, ${token.colorBgContainer} 100%)`, boxShadow: '0 8px 24px rgba(0,0,0,0.04)' }} styles={{ body: { padding: 24 } }}>
            <Flex justify="space-between" align="center" gap={16} wrap="wrap">
              <div>
                <Text type="secondary" style={{ textTransform: 'uppercase', letterSpacing: 0.8, fontWeight: 600 }}>{t('Dashboard')}</Text>
                <Title level={2} style={{ margin: '4px 0 8px' }}>{t('Hello, {{name}}', { name: patientName })}</Title>
                <Text type="secondary" style={{ fontSize: 15 }}>{t('Manage your health journey')}</Text>
              </div>
              <DesktopButton type="primary" size="large" icon={<IconCalendar size={20} />} href="/search">{t('Book Appointment')}</DesktopButton>
            </Flex>
            {stats && (
              <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
                <Col xs={24} sm={8}><DesktopCard size="small" bordered style={{ borderRadius: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}><Statistic title={t('Upcoming')} value={stats.upcoming} valueStyle={{ color: token.colorPrimary }} /></DesktopCard></Col>
                <Col xs={24} sm={8}><DesktopCard size="small" bordered style={{ borderRadius: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}><Statistic title={t('Completed')} value={stats.completed} /></DesktopCard></Col>
                <Col xs={24} sm={8}><DesktopCard size="small" bordered style={{ borderRadius: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}><Statistic title={t('Cancelled')} value={stats.cancelled} /></DesktopCard></Col>
              </Row>
            )}
          </DesktopCard>

          <Row gutter={[24, 24]} style={{ marginTop: 24 }}>
            <Col xs={24} lg={16}>
              <DesktopCard title={t('Your Appointments')} bordered={false} style={{ borderRadius: 16, boxShadow: '0 1px 6px rgba(0,0,0,0.04)' }} styles={{ header: { borderBottom: '1px solid ' + token.colorBorderSecondary } }}>
                <DesktopTabs defaultActiveKey="upcoming" items={items} />
              </DesktopCard>
            </Col>
            <Col xs={24} lg={8}>
              <Flex vertical gap="large">
                <DesktopCard title={t('Quick Actions')} bordered={false} style={{ borderRadius: 16, boxShadow: '0 1px 6px rgba(0,0,0,0.04)' }}>
                  <Flex vertical gap="small">
                    <DesktopButton block icon={<IconFileText size={16} />} style={{ textAlign: 'left' }}>{t('Medical Records')}</DesktopButton>
                    <DesktopButton block icon={<IconUser size={16} />} style={{ textAlign: 'left' }} href="/profile">{t('Edit Profile')}</DesktopButton>
                  </Flex>
                </DesktopCard>
                <DesktopCard bordered={false} style={{ borderRadius: 16, background: `linear-gradient(135deg, ${token.colorPrimary} 0%, ${token.colorPrimaryHover} 100%)`, color: 'white', boxShadow: '0 8px 24px rgba(0,0,0,0.08)' }}>
                  <Title level={5} style={{ color: 'white', marginTop: 0 }}>{t('Get the Medic App')}</Title>
                  <Text style={{ color: 'rgba(255,255,255,0.92)', marginBottom: 16, display: 'block' }}>{t('Manage appointments on the go with our mobile app.')}</Text>
                  <DesktopButton ghost style={{ color: 'white', borderColor: 'white' }}>{t('Download')}</DesktopButton>
                </DesktopCard>
              </Flex>
            </Col>
          </Row>
        </div>
      </div>

      <Modal title={<div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><HeartOutlined style={{ color: token.colorError }} /><span>{t('Appreciate Doctor')}</span></div>} open={appreciationModalOpen} onOk={handleAppreciateSubmit} onCancel={() => setAppreciationModalOpen(false)} okText={t('Send Appreciation')} okButtonProps={{ loading: loadingKey === (selectedAppointmentId ? `appreciate:${selectedAppointmentId}` : null), style: { backgroundColor: token.colorError, borderColor: token.colorError } }}>
        <p>{t('Would you like to leave a short thank-you note? (Optional)')}</p>
        <Input.TextArea rows={4} value={appreciationNote} onChange={(e) => setAppreciationNote(e.target.value)} placeholder={t('e.g. Very kind and caring...')} maxLength={80} showCount />
      </Modal>

      <ExperienceProfileModal
        open={profileModalOpen}
        onClose={() => setProfileModalOpen(false)}
        onSubmit={handleProfileSubmit}
        loading={loadingKey === `profile:${selectedProfileId}`}
      />
    </>
  )
}

// =============================================================================
// EXPERIENCE PROFILE MODAL
// =============================================================================

const ExperienceProfileModal = ({
  open,
  onClose,
  onSubmit,
  loading
}: {
  open: boolean
  onClose: () => void
  onSubmit: (data: Record<string, number>) => void
  loading: boolean
}) => {
  const { t } = useTranslation('default')
  const [data, setData] = useState<Record<string, number>>({})
  const isMobile = useIsMobile()

  // Reset when opened
  useMemo(() => {
    if (open) {
      const initial: Record<string, number> = {}
      EXPERIENCE_SLIDERS.forEach((s) => (initial[s.key] = 50))
      setData(initial)
    }
  }, [open])

  const handleChange = (key: string, val: number | number[]) => {
    const value = Array.isArray(val) ? val[0] : val
    setData((prev) => ({ ...prev, [key]: value }))
  }

  const SliderComponent = isMobile ? MobileSlider : DesktopSlider

  return (
    <Modal
      title={null}
      open={open}
      onCancel={onClose}
      footer={null}
      destroyOnClose
      width={600}
      centered
    >
      <div style={{ padding: '0 10px' }}>
        <h3 style={{ fontSize: 18, fontWeight: 600, marginBottom: 8, textAlign: 'center' }}>
          {t('Help other patients choose the right doctor')}
        </h3>
        <p style={{ color: '#666', fontSize: 13, textAlign: 'center', marginBottom: 24 }}>
          {t('Use the sliders to describe your experience. This is not a rating, just a description of their style.')}
        </p>

        {EXPERIENCE_SLIDERS.map((slider) => (
          <div key={slider.key} style={{ marginBottom: 24 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 8, fontSize: 14, fontWeight: 500 }}>
              <span style={{ color: '#0d9488' }}>🟦 {t(slider.label)}</span>
            </div>
            <SliderComponent
              min={0}
              max={100}
              value={data[slider.key] ?? 50}
              onChange={(val: number | number[]) => handleChange(slider.key, val)}
              tooltip={isMobile ? undefined : { formatter: null }}
            />
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: '#666', marginTop: 4 }}>
              <span style={{ maxWidth: '45%' }}>{t(slider.start)}</span>
              <span style={{ maxWidth: '45%', textAlign: 'right' }}>{t(slider.end)}</span>
            </div>
          </div>
        ))}

        <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 12, marginTop: 32 }}>
          <DesktopButton onClick={onClose}>{t('Skip')}</DesktopButton>
          <DesktopButton type="primary" onClick={() => onSubmit(data)} loading={loading}>
            {t('Submit Profile')}
          </DesktopButton>
        </div>
      </div>
    </Modal>
  )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================// =============================================================================
// MAIN COMPONENT
// =============================================================================

const PatientDashboardPage = ({ app, auth, upcomingAppointments, pastAppointments, patient, stats, myDoctors, activeTab }: PageProps) => {
  const isMobile = useIsMobile()

  // If activeTab is 'doctors', show My Doctors list
  if (activeTab === 'doctors') {
    return (
      <div style={{ minHeight: '100vh', padding: isMobile ? 16 : 24 }}>
        <MyDoctorsList doctors={myDoctors || []} />
      </div>
    )
  }

  if (isMobile) {
    return <MobilePatientDashboard upcomingAppointments={upcomingAppointments} pastAppointments={pastAppointments} patient={patient} stats={stats} />
  }

  return <DesktopPatientDashboard upcomingAppointments={upcomingAppointments} pastAppointments={pastAppointments} patient={patient} stats={stats} />
}

export default PatientDashboardPage
