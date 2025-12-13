import {
  Button,
  Card,
  Col,
  Row,
  Divider,
  Typography,
  Tabs,
  Tag,
  Empty,
  Flex,
  theme,
  Statistic
} from 'antd'
import {
  IconCalendar,
  IconCalendarEvent,
  IconClock,
  IconFileText,
  IconUser,
  IconVideo,
  IconMapPin
} from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import dayjs from 'dayjs'

import type { AppPageProps } from '@/types/app'

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

const PatientDashboard = ({ upcomingAppointments = [], pastAppointments = [], patient, stats }: PageProps) => {
  const { t } = useTranslation('default')
  const { token } = useToken()
  const patientName = patient?.firstName || t('dashboard.patient_fallback', 'there')

  const renderAppointment = (appt: Appointment, isUpcoming: boolean) => {
    const mode = appt.consultationMode || 'in_person'
    const isVideo = mode === 'video' || mode === 'telemedicine'
    const doctorSpecialty = appt.doctor.specialty || t('dashboard.general_specialty', 'General practice')

    return (
    <Card
      key={appt.id}
      style={{ width: '100%', marginBottom: 16, borderRadius: 12, borderColor: '#e2e8f0' }}
      bodyStyle={{ padding: 24 }}
    >
      <Row gutter={[16, 16]} align="middle">
        <Col xs={24} sm={16}>
          <Flex gap="middle" align="start">
            <div
              style={{
                width: 48,
                height: 48,
                borderRadius: '50%',
                backgroundColor: '#f1f5f9',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#64748b',
                flexShrink: 0
              }}
            >
              {appt.doctor.avatarUrl ? (
                <img src={appt.doctor.avatarUrl} alt="Doctor" style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }} />
              ) : (
                <IconUser size={24} />
              )}
            </div>
            <div>
              <Text strong style={{ fontSize: 16, display: 'block' }}>
                Dr. {appt.doctor.firstName} {appt.doctor.lastName}
              </Text>
              <Text type="secondary" style={{ display: 'block' }}>{doctorSpecialty}</Text>
              <Flex gap="small" style={{ marginTop: 8 }} align="center">
                {isVideo ? <IconVideo size={14} color="#0d9488" /> : <IconMapPin size={14} color="#0d9488" />}
                <Text style={{ fontSize: 13, color: '#0d9488' }}>
                  {isVideo ? t('dashboard.video_visit', 'Video Visit') : t('dashboard.in_person', 'In-person')}
                </Text>
              </Flex>
            </div>
          </Flex>
        </Col>

        <Col xs={24} sm={8}>
          <Flex vertical align="end" gap="small" style={{ textAlign: 'right' }}>
            <Flex gap="small" align="center">
              <IconCalendarEvent size={16} />
              <Text strong>{dayjs(appt.startsAt).format('MMM D, YYYY')}</Text>
            </Flex>
            <Flex gap="small" align="center">
              <IconClock size={16} />
              <Text>{dayjs(appt.startsAt).format('h:mm A')}</Text>
            </Flex>
            <Tag color={getStatusColor(appt.status)}>
              {t(`dashboard.status.${appt.status}`, appt.status)}
            </Tag>
          </Flex>
        </Col>
      </Row>

      {isUpcoming && (
        <>
          <Divider style={{ margin: '16px 0' }} />
          <Flex justify="flex-end" gap="small">
            {isVideo && (
              <Button type="primary" icon={<IconVideo size={16} />}>
                {t('dashboard.join_call', 'Join Call')}
              </Button>
            )}
            <Button danger>
              {t('dashboard.cancel', 'Cancel')}
            </Button>
            <Button>
              {t('dashboard.reschedule', 'Reschedule')}
            </Button>
          </Flex>
        </>
      )}
    </Card>
  )}

  const items = [
    {
      key: 'upcoming',
      label: t('dashboard.tabs.upcoming', 'Upcoming'),
      children: upcomingAppointments.length > 0 ? (
        upcomingAppointments.map((appt: Appointment) => renderAppointment(appt, true))
      ) : (
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description={t('dashboard.no_upcoming', 'No upcoming appointments')}
        >
          <Button type="primary" href="/search">
            {t('dashboard.book_now', 'Book a new appointment')}
          </Button>
        </Empty>
      )
    },
    {
      key: 'past',
      label: t('dashboard.tabs.past', 'Past'),
      children: pastAppointments.length > 0 ? (
        pastAppointments.map((appt: Appointment) => renderAppointment(appt, false))
      ) : (
        <Empty description={t('dashboard.no_history', 'No past appointments')} />
      )
    }
  ]

  return (
    <div style={{ minHeight: '100vh', background: token.colorBgLayout }}>
      <div style={{ maxWidth: 1200, margin: '0 auto', padding: '24px' }}>
        <Card
          bordered={false}
          style={{
            borderRadius: 16,
            background: `linear-gradient(120deg, ${token.colorPrimaryBg} 0%, ${token.colorBgContainer} 100%)`,
            boxShadow: '0 8px 24px rgba(0,0,0,0.04)'
          }}
          bodyStyle={{ padding: 24 }}
        >
          <Flex justify="space-between" align="center" gap={16} wrap="wrap">
            <div>
              <Text type="secondary" style={{ textTransform: 'uppercase', letterSpacing: 0.8, fontWeight: 600 }}>
                {t('dashboard.greeting', 'Dashboard')}
              </Text>
              <Title level={2} style={{ margin: '4px 0 8px' }}>
                {t('dashboard.welcome', 'Hello, {{name}}', { name: patientName })}
              </Title>
              <Text type="secondary" style={{ fontSize: 15 }}>
                {t('dashboard.subtitle', 'Manage your health journey')}
              </Text>
            </div>
            <Button type="primary" size="large" icon={<IconCalendar size={20} />} href="/search">
              {t('dashboard.book_new', 'Book Appointment')}
            </Button>
          </Flex>
          {stats && (
            <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
              <Col xs={24} sm={8}>
                <Card size="small" bordered style={{ borderRadius: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                  <Statistic title={t('dashboard.stats.upcoming', 'Upcoming')} value={stats.upcoming} valueStyle={{ color: token.colorPrimary }} />
                </Card>
              </Col>
              <Col xs={24} sm={8}>
                <Card size="small" bordered style={{ borderRadius: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                  <Statistic title={t('dashboard.stats.completed', 'Completed')} value={stats.completed} />
                </Card>
              </Col>
              <Col xs={24} sm={8}>
                <Card size="small" bordered style={{ borderRadius: 12, boxShadow: '0 1px 4px rgba(0,0,0,0.04)' }}>
                  <Statistic title={t('dashboard.stats.cancelled', 'Cancelled')} value={stats.cancelled} />
                </Card>
              </Col>
            </Row>
          )}
        </Card>

        <Row gutter={[24, 24]} style={{ marginTop: 24 }}>
          <Col xs={24} lg={16}>
            <Card
              title={t('dashboard.appointments', 'Your Appointments')}
              bordered={false}
              style={{ borderRadius: 16, boxShadow: '0 1px 6px rgba(0,0,0,0.04)' }}
              headStyle={{ borderBottom: '1px solid ' + token.colorBorderSecondary }}
            >
              <Tabs defaultActiveKey="upcoming" items={items} />
            </Card>
          </Col>

          <Col xs={24} lg={8}>
            <Flex vertical gap="large">
              <Card
                title={t('dashboard.quick_actions', 'Quick Actions')}
                bordered={false}
                style={{ borderRadius: 16, boxShadow: '0 1px 6px rgba(0,0,0,0.04)' }}
              >
                <Flex vertical gap="small">
                  <Button block icon={<IconFileText size={16} />} style={{ textAlign: 'left' }}>
                    {t('dashboard.medical_records', 'Medical Records')}
                  </Button>
                  <Button block icon={<IconUser size={16} />} style={{ textAlign: 'left' }} href="/profile">
                    {t('dashboard.profile', 'Edit Profile')}
                  </Button>
                </Flex>
              </Card>

              <Card
                bordered={false}
                style={{
                  borderRadius: 16,
                  background: `linear-gradient(135deg, ${token.colorPrimary} 0%, ${token.colorPrimaryHover} 100%)`,
                  color: 'white',
                  boxShadow: '0 8px 24px rgba(0,0,0,0.08)'
                }}
              >
                <Title level={5} style={{ color: 'white', marginTop: 0 }}>
                  {t('dashboard.get_app', 'Get the Medic App')}
                </Title>
                <Text style={{ color: 'rgba(255,255,255,0.92)', marginBottom: 16, display: 'block' }}>
                  {t('dashboard.app_promo', 'Manage appointments on the go with our mobile app.')}
                </Text>
                <Button ghost style={{ color: 'white', borderColor: 'white' }}>
                  {t('dashboard.download', 'Download')}
                </Button>
              </Card>
            </Flex>
          </Col>
        </Row>
      </div>
    </div>
  )
}

const getStatusColor = (status: string) => {
  switch (status) {
    case 'confirmed':
      return 'success'
    case 'pending':
      return 'warning'
    case 'held':
      return 'warning'
    case 'cancelled':
      return 'error'
    case 'no_show':
      return 'error'
    case 'completed':
      return 'default'
    default:
      return 'default'
  }
}

export default PatientDashboard
