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
  Input
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
  IconInfoCircle
} from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import dayjs from 'dayjs'
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
  TextArea as MobileTextArea
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

// =============================================================================
// MOBILE PATIENT DASHBOARD
// =============================================================================

function MobilePatientDashboard({ upcomingAppointments = [], pastAppointments = [], patient, stats }: Omit<PageProps, 'app' | 'auth'>) {
  const { t } = useTranslation('default')
  const [upcoming, setUpcoming] = useState(upcomingAppointments)
  const [past, setPast] = useState(pastAppointments)
  const [loadingKey, setLoadingKey] = useState<string | null>(null)
  const patientName = patient?.firstName || t('dashboard.patient_fallback', 'there')

  const handleApprove = async (id: string) => {
    setLoadingKey(`approve:${id}`)
    try {
      const res = await fetch(`/appointments/${id}/approve_reschedule`, {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() }
      })
      if (!res.ok) throw new Error('approve_failed')
      Toast.show({ icon: 'success', content: t('dashboard.approve_success', 'Reschedule approved') })
      window.location.reload()
    } catch (err) {
      Toast.show({ icon: 'fail', content: t('dashboard.approve_error', 'Something went wrong') })
      setLoadingKey(null)
    }
  }

  const handleReject = async (id: string) => {
    setLoadingKey(`reject:${id}`)
    try {
      const body = new URLSearchParams({ reason: t('dashboard.reject_reason', 'You declined this reschedule') })
      const res = await fetch(`/appointments/${id}/reject_reschedule`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() },
        body: body.toString()
      })
      if (!res.ok) throw new Error('reject_failed')
      Toast.show({ icon: 'success', content: t('dashboard.reject_success', 'Reschedule rejected') })
      setUpcoming((prev) => prev.filter((item) => item.id !== id))
    } catch (err) {
      Toast.show({ icon: 'fail', content: t('dashboard.reject_error', 'Unable to reject') })
      setLoadingKey(null)
    }
  }

  const handleCancel = async (id: string) => {
    const result = await Dialog.confirm({
      content: t('dashboard.cancel_confirm_desc', 'This will remove your booking.')
    })
    if (!result) return

    setLoadingKey(`cancel:${id}`)
    try {
      const body = new URLSearchParams({ reason: t('dashboard.cancel_reason', 'Cancelled by patient') })
      const res = await fetch(`/appointments/${id}/cancel`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/x-www-form-urlencoded', 'X-Requested-With': 'XMLHttpRequest', 'x-csrf-token': getCsrfToken() },
        body: body.toString()
      })
      if (!res.ok) throw new Error('cancel_failed')
      Toast.show({ icon: 'success', content: t('dashboard.cancel_success', 'Appointment cancelled') })
      setUpcoming((prev) => prev.filter((item) => item.id !== id))
    } catch (err) {
      Toast.show({ icon: 'fail', content: t('dashboard.cancel_error', 'Unable to cancel') })
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
        Toast.show({ content: t('dashboard.already_appreciated', 'Already appreciated') })
      } else if (!res.ok) {
        throw new Error('appreciation_failed')
      } else {
        Toast.show({ icon: 'success', content: t('dashboard.appreciation_sent', 'Thank you!') })
      }
      setPast((prev) => prev.map((appt) => (appt.id === id ? { ...appt, appreciated: true } : appt)))
    } catch (err) {
      Toast.show({ icon: 'fail', content: t('dashboard.appreciation_error', 'Unable to send') })
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
            <div style={{ fontWeight: 600, fontSize: 15, marginBottom: 2 }}>
              Dr. {appt.doctor.firstName} {appt.doctor.lastName}
            </div>
            <div style={{ color: '#666', fontSize: 13, marginBottom: 6 }}>
              {appt.doctor.specialty || 'General Practice'}
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, fontSize: 12, color: '#888' }}>
              <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <CalendarOutline fontSize={12} />
                {dayjs(appt.startsAt).format('MMM D')}
              </span>
              <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                <ClockCircleOutline fontSize={12} />
                {dayjs(appt.startsAt).format('h:mm A')}
              </span>
              <MobileTag color={getStatusColor(appt.status)} fill="outline" style={{ fontSize: 10 }}>
                {appt.status}
              </MobileTag>
            </div>
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
              ⚠️ {t('dashboard.pending_title', 'Review this rescheduled time')}
            </div>
            <div style={{ display: 'flex', gap: 8 }} onClick={(e) => e.stopPropagation()}>
              <MobileButton
                size="small"
                color="primary"
                loading={loadingKey === `approve:${appt.id}`}
                onClick={() => handleApprove(appt.id)}
              >
                Approve
              </MobileButton>
              <MobileButton
                size="small"
                loading={loadingKey === `reject:${appt.id}`}
                onClick={() => handleReject(appt.id)}
              >
                Reject
              </MobileButton>
            </div>
          </div>
        )}

        {/* Pending cancel action */}
        {isUpcoming && isPendingApproval && !isReschedulePending && (
          <div style={{ marginTop: 12 }} onClick={(e) => e.stopPropagation()}>
            <MobileButton
              size="small"
              color="danger"
              fill="outline"
              loading={loadingKey === `cancel:${appt.id}`}
              onClick={() => handleCancel(appt.id)}
            >
              Cancel
            </MobileButton>
          </div>
        )}

        {/* Appreciate button for past completed */}
        {!isUpcoming && appt.status === 'completed' && !appt.appreciated && (
          <div style={{ marginTop: 12 }} onClick={(e) => e.stopPropagation()}>
            <MobileButton
              size="small"
              color="danger"
              loading={loadingKey === `appreciate:${appt.id}`}
              onClick={() => handleAppreciate(appt.id)}
            >
              ♥ Appreciate
            </MobileButton>
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
          {t('dashboard.greeting', 'Dashboard')}
        </p>
        <h2 style={{ fontSize: 22, fontWeight: 700, margin: '0 0 4px' }}>
          {t('dashboard.welcome', 'Hello, {{name}}', { name: patientName })}
        </h2>
        <p style={{ color: '#666', margin: 0, fontSize: 14 }}>
          {t('dashboard.subtitle', 'Manage your health journey')}
        </p>
      </div>

      {/* Stats */}
      {stats && (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 8, marginBottom: 20 }}>
          <div style={{ backgroundColor: '#fff', borderRadius: 10, padding: 12, textAlign: 'center', border: '1px solid #f0f0f0' }}>
            <div style={{ fontSize: 22, fontWeight: 700, color: '#0d9488' }}>{stats.upcoming}</div>
            <div style={{ fontSize: 11, color: '#888' }}>Upcoming</div>
          </div>
          <div style={{ backgroundColor: '#fff', borderRadius: 10, padding: 12, textAlign: 'center', border: '1px solid #f0f0f0' }}>
            <div style={{ fontSize: 22, fontWeight: 700 }}>{stats.completed}</div>
            <div style={{ fontSize: 11, color: '#888' }}>Completed</div>
          </div>
          <div style={{ backgroundColor: '#fff', borderRadius: 10, padding: 12, textAlign: 'center', border: '1px solid #f0f0f0' }}>
            <div style={{ fontSize: 22, fontWeight: 700, color: '#dc2626' }}>{stats.cancelled}</div>
            <div style={{ fontSize: 11, color: '#888' }}>Cancelled</div>
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
        {t('dashboard.book_new', 'Book Appointment')}
      </MobileButton>

      {/* Appointments Tabs */}
      <MobileTabs>
        <MobileTabs.Tab title={`Upcoming (${upcoming.length})`} key="upcoming">
          <div style={{ paddingTop: 12 }}>
            {upcoming.length > 0 ? (
              upcoming.map((appt) => renderMobileAppointment(appt, true))
            ) : (
              <Empty description={t('dashboard.no_upcoming', 'No upcoming appointments')} />
            )}
          </div>
        </MobileTabs.Tab>
        <MobileTabs.Tab title={`Past (${past.length})`} key="past">
          <div style={{ paddingTop: 12 }}>
            {past.length > 0 ? (
              past.map((appt) => renderMobileAppointment(appt, false))
            ) : (
              <Empty description={t('dashboard.no_history', 'No past appointments')} />
            )}
          </div>
        </MobileTabs.Tab>
      </MobileTabs>
    </div>
  )
}

// =============================================================================
// DESKTOP PATIENT DASHBOARD (Original)
// =============================================================================

function DesktopPatientDashboard({ upcomingAppointments = [], pastAppointments = [], patient, stats }: Omit<PageProps, 'app' | 'auth'>) {
  const { t } = useTranslation('default')
  const { token } = useToken()
  const [messageApi, contextHolder] = message.useMessage()
  const [upcoming, setUpcoming] = useState(upcomingAppointments)
  const [past, setPast] = useState(pastAppointments)
  const [loadingKey, setLoadingKey] = useState<string | null>(null)
  const patientName = patient?.firstName || t('dashboard.patient_fallback', 'there')

  // Appreciation State
  const [appreciationModalOpen, setAppreciationModalOpen] = useState(false)
  const [selectedAppointmentId, setSelectedAppointmentId] = useState<string | null>(null)
  const [appreciationNote, setAppreciationNote] = useState('')

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
      const body = new URLSearchParams({ reason: t('dashboard.reject_reason', 'You declined this reschedule') })
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
      const body = new URLSearchParams({ reason: t('dashboard.cancel_reason', 'Cancelled by patient') })
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
    const doctorSpecialty = appt.doctor.specialty || t('dashboard.general_specialty', 'General practice')
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
                <Text strong style={{ fontSize: 16, display: 'block' }}>Dr. {appt.doctor.firstName} {appt.doctor.lastName}</Text>
                <Text type="secondary" style={{ display: 'block' }}>{doctorSpecialty}</Text>
                <Flex gap="small" style={{ marginTop: 8 }} align="center">
                  {isVideo ? <IconVideo size={14} color="#0d9488" /> : <IconMapPin size={14} color="#0d9488" />}
                  <Text style={{ fontSize: 13, color: '#0d9488' }}>{isVideo ? t('dashboard.video_visit', 'Video Visit') : t('dashboard.in_person', 'In-person')}</Text>
                </Flex>
              </div>
            </Flex>
          </Col>
          <Col xs={24} sm={8}>
            <Flex vertical align="end" gap="small" style={{ textAlign: 'right' }}>
              <Flex gap="small" align="center"><IconCalendarEvent size={16} /><Text strong style={{ color: dateColor }}>{dayjs(appt.startsAt).format('MMM D, YYYY')}</Text></Flex>
              <Flex gap="small" align="center"><IconClock size={16} /><Text style={{ color: dateColor }}>{dayjs(appt.startsAt).format('h:mm A')}</Text></Flex>
              <Tag color={getStatusColor(appt.status)}>{t(`dashboard.status.${appt.status}`, appt.status)}</Tag>
            </Flex>
          </Col>
        </Row>

        {isUpcoming && (
          <>
            <Divider style={{ margin: '16px 0' }} />
            {isReschedulePending && (
              <Alert type="warning" showIcon icon={<IconInfoCircle size={16} color={token.colorWarningText} />} message={t('dashboard.pending_title', 'Review this rescheduled time')} description={t('dashboard.pending_tip', 'Confirm if the new time works or choose to reject it.')} style={{ marginBottom: 12, background: token.colorWarningBg, borderColor: token.colorWarningBorder, borderRadius: 10 }} />
            )}
            <Flex justify="flex-end" gap="small" wrap>
              {isReschedulePending ? (
                <>
                  <DesktopButton type="primary" onClick={() => handleApprove(appt.id)} loading={loadingKey === `approve:${appt.id}`}>{t('dashboard.approve', 'Approve')}</DesktopButton>
                  <Popconfirm title={t('dashboard.reject_confirm_title', 'Reject this rescheduled time?')} description={t('dashboard.reject_confirm_desc', 'This booking will be cancelled if you reject.')} okText={t('dashboard.yes', 'Yes')} cancelText={t('dashboard.no', 'No')} onConfirm={() => handleReject(appt.id)}>
                    <DesktopButton loading={loadingKey === `reject:${appt.id}`}>{t('dashboard.reject', 'Reject')}</DesktopButton>
                  </Popconfirm>
                </>
              ) : (
                <>
                  {isPendingApproval ? (
                    <Flex align="center" gap="small" wrap>
                      <Text type="secondary">{t('dashboard.awaiting_doctor', 'Waiting for your doctor to confirm')}</Text>
                      <Popconfirm title={t('dashboard.cancel_confirm_title', 'Cancel this appointment?')} description={t('dashboard.cancel_confirm_desc', 'This will remove your booking.')} okText={t('dashboard.yes', 'Yes')} cancelText={t('dashboard.no', 'No')} onConfirm={() => handleCancel(appt.id)}>
                        <DesktopButton loading={loadingKey === `cancel:${appt.id}`} danger>{t('dashboard.cancel', 'Cancel')}</DesktopButton>
                      </Popconfirm>
                    </Flex>
                  ) : (
                    <>
                      {isVideo && <DesktopButton type="primary" icon={<IconVideo size={16} />}>{t('dashboard.join_call', 'Join Call')}</DesktopButton>}
                      <DesktopButton danger>{t('dashboard.cancel', 'Cancel')}</DesktopButton>
                      <DesktopButton>{t('dashboard.reschedule', 'Reschedule')}</DesktopButton>
                    </>
                  )}
                </>
              )}
            </Flex>
          </>
        )}

        {!isUpcoming && appt.status === 'completed' && !appt.appreciated && (
          <>
            <Divider style={{ margin: '16px 0' }} />
            <Flex justify="flex-end">
              <DesktopButton type="primary" icon={<HeartOutlined />} style={{ backgroundColor: token.colorError, borderColor: token.colorError }} onClick={() => openAppreciationModal(appt.id)}>Appreciate Doctor</DesktopButton>
            </Flex>
          </>
        )}
      </DesktopCard>
    )
  }

  const items = useMemo(() => ([
    { key: 'upcoming', label: t('dashboard.tabs.upcoming', 'Upcoming'), children: upcoming.length > 0 ? upcoming.map((appt) => renderAppointment(appt, true)) : <DesktopEmpty image={DesktopEmpty.PRESENTED_IMAGE_SIMPLE} description={t('dashboard.no_upcoming', 'No upcoming appointments')}><DesktopButton type="primary" href="/search">{t('dashboard.book_now', 'Book a new appointment')}</DesktopButton></DesktopEmpty> },
    { key: 'past', label: t('dashboard.tabs.past', 'Past'), children: past.length > 0 ? past.map((appt) => renderAppointment(appt, false)) : <DesktopEmpty description={t('dashboard.no_history', 'No past appointments')} /> }
  ]), [upcoming, past, renderAppointment, t])

  return (
    <>
      {contextHolder}
      <div style={{ minHeight: '100vh', background: token.colorBgLayout }}>
        <div style={{ maxWidth: 1200, margin: '0 auto', padding: '24px' }}>
          <DesktopCard bordered={false} style={{ borderRadius: 16, background: `linear-gradient(120deg, ${token.colorPrimaryBg} 0%, ${token.colorBgContainer} 100%)`, boxShadow: '0 8px 24px rgba(0,0,0,0.04)' }} styles={{ body: { padding: 24 } }}>
            <Flex justify="space-between" align="center" gap={16} wrap="wrap">
              <div>
                <Text type="secondary" style={{ textTransform: 'uppercase', letterSpacing: 0.8, fontWeight: 600 }}>{t('dashboard.greeting', 'Dashboard')}</Text>
                <Title level={2} style={{ margin: '4px 0 8px' }}>{t('dashboard.welcome', 'Hello, {{name}}', { name: patientName })}</Title>
                <Text type="secondary" style={{ fontSize: 15 }}>{t('dashboard.subtitle', 'Manage your health journey')}</Text>
              </div>
              <DesktopButton type="primary" size="large" icon={<IconCalendar size={20} />} href="/search">{t('dashboard.book_new', 'Book Appointment')}</DesktopButton>
            </Flex>
            {stats && (
              <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
                <Col xs={24} sm={8}><DesktopCard size="small" bordered style={{ borderRadius: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}><Statistic title={t('dashboard.stats.upcoming', 'Upcoming')} value={stats.upcoming} valueStyle={{ color: token.colorPrimary }} /></DesktopCard></Col>
                <Col xs={24} sm={8}><DesktopCard size="small" bordered style={{ borderRadius: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}><Statistic title={t('dashboard.stats.completed', 'Completed')} value={stats.completed} /></DesktopCard></Col>
                <Col xs={24} sm={8}><DesktopCard size="small" bordered style={{ borderRadius: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}><Statistic title={t('dashboard.stats.cancelled', 'Cancelled')} value={stats.cancelled} /></DesktopCard></Col>
              </Row>
            )}
          </DesktopCard>

          <Row gutter={[24, 24]} style={{ marginTop: 24 }}>
            <Col xs={24} lg={16}>
              <DesktopCard title={t('dashboard.appointments', 'Your Appointments')} bordered={false} style={{ borderRadius: 16, boxShadow: '0 1px 6px rgba(0,0,0,0.04)' }} styles={{ header: { borderBottom: '1px solid ' + token.colorBorderSecondary } }}>
                <DesktopTabs defaultActiveKey="upcoming" items={items} />
              </DesktopCard>
            </Col>
            <Col xs={24} lg={8}>
              <Flex vertical gap="large">
                <DesktopCard title={t('dashboard.quick_actions', 'Quick Actions')} bordered={false} style={{ borderRadius: 16, boxShadow: '0 1px 6px rgba(0,0,0,0.04)' }}>
                  <Flex vertical gap="small">
                    <DesktopButton block icon={<IconFileText size={16} />} style={{ textAlign: 'left' }}>{t('dashboard.medical_records', 'Medical Records')}</DesktopButton>
                    <DesktopButton block icon={<IconUser size={16} />} style={{ textAlign: 'left' }} href="/profile">{t('dashboard.profile', 'Edit Profile')}</DesktopButton>
                  </Flex>
                </DesktopCard>
                <DesktopCard bordered={false} style={{ borderRadius: 16, background: `linear-gradient(135deg, ${token.colorPrimary} 0%, ${token.colorPrimaryHover} 100%)`, color: 'white', boxShadow: '0 8px 24px rgba(0,0,0,0.08)' }}>
                  <Title level={5} style={{ color: 'white', marginTop: 0 }}>{t('dashboard.get_app', 'Get the Medic App')}</Title>
                  <Text style={{ color: 'rgba(255,255,255,0.92)', marginBottom: 16, display: 'block' }}>{t('dashboard.app_promo', 'Manage appointments on the go with our mobile app.')}</Text>
                  <DesktopButton ghost style={{ color: 'white', borderColor: 'white' }}>{t('dashboard.download', 'Download')}</DesktopButton>
                </DesktopCard>
              </Flex>
            </Col>
          </Row>
        </div>
      </div>

      <Modal title={<div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><HeartOutlined style={{ color: token.colorError }} /><span>Appreciate Doctor</span></div>} open={appreciationModalOpen} onOk={handleAppreciateSubmit} onCancel={() => setAppreciationModalOpen(false)} okText="Send Appreciation" okButtonProps={{ loading: loadingKey === (selectedAppointmentId ? `appreciate:${selectedAppointmentId}` : null), style: { backgroundColor: token.colorError, borderColor: token.colorError } }}>
        <p>Would you like to leave a short thank-you note? (Optional)</p>
        <Input.TextArea rows={4} value={appreciationNote} onChange={(e) => setAppreciationNote(e.target.value)} placeholder="e.g. Very kind and caring..." maxLength={80} showCount />
      </Modal>
    </>
  )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

const PatientDashboard = ({ upcomingAppointments = [], pastAppointments = [], patient, stats }: PageProps) => {
  const isMobile = useIsMobile()

  if (isMobile) {
    return <MobilePatientDashboard upcomingAppointments={upcomingAppointments} pastAppointments={pastAppointments} patient={patient} stats={stats} />
  }

  return <DesktopPatientDashboard upcomingAppointments={upcomingAppointments} pastAppointments={pastAppointments} patient={patient} stats={stats} />
}

export default PatientDashboard
