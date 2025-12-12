import {
  Button,
  Card,
  Col,
  Row,
  Divider,
  Typography,
  Tabs,
  Tag,
  Space,
  Empty,
  Flex
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
import { Link, router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import dayjs from 'dayjs'

import type { AppPageProps } from '@/types/app'

const { Title, Text } = Typography

type Appointment = {
  id: string
  doctor: {
    first_name: string
    last_name: string
    specialty: { name: string }
    avatar_url?: string
  }
  starts_at: string
  status: 'confirmed' | 'pending' | 'cancelled' | 'completed'
  type: 'in-person' | 'video'
}

type PageProps = AppPageProps<{
  upcomingAppointments: Appointment[]
  pastAppointments: Appointment[]
  user: {
    first_name: string
    last_name: string
  }
}>

const PatientDashboard = ({ upcomingAppointments, pastAppointments, user }: PageProps) => {
  const { t } = useTranslation('default')

  const renderAppointment = (appt: Appointment, isUpcoming: boolean) => (
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
              {appt.doctor.avatar_url ? (
                <img src={appt.doctor.avatar_url} alt="Doctor" style={{ width: '100%', height: '100%', borderRadius: '50%', objectFit: 'cover' }} />
              ) : (
                <IconUser size={24} />
              )}
            </div>
            <div>
              <Text strong style={{ fontSize: 16, display: 'block' }}>
                Dr. {appt.doctor.first_name} {appt.doctor.last_name}
              </Text>
              <Text type="secondary" style={{ display: 'block' }}>{appt.doctor.specialty.name}</Text>
              <Flex gap="small" style={{ marginTop: 8 }} align="center">
                {appt.type === 'video' ? <IconVideo size={14} color="#0d9488" /> : <IconMapPin size={14} color="#0d9488" />}
                <Text style={{ fontSize: 13, color: '#0d9488' }}>
                  {appt.type === 'video' ? t('dashboard.video_visit', 'Video Visit') : t('dashboard.in_person', 'In-person')}
                </Text>
              </Flex>
            </div>
          </Flex>
        </Col>

        <Col xs={24} sm={8}>
          <Flex vertical align="end" gap="small" style={{ textAlign: 'right' }}>
            <Flex gap="small" align="center">
              <IconCalendarEvent size={16} />
              <Text strong>{dayjs(appt.starts_at).format('MMM D, YYYY')}</Text>
            </Flex>
            <Flex gap="small" align="center">
              <IconClock size={16} />
              <Text>{dayjs(appt.starts_at).format('h:mm A')}</Text>
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
            {appt.type === 'video' && (
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
  )

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
    <div style={{ minHeight: '100vh', backgroundColor: '#f8fafc', paddingBottom: 40 }}>
      <div style={{ backgroundColor: 'white', borderBottom: '1px solid #e2e8f0', padding: '24px 0' }}>
        <div style={{ maxWidth: 1000, margin: '0 auto', padding: '0 24px' }}>
          <Flex justify="space-between" align="center">
            <div>
              <Title level={2} style={{ margin: 0 }}>
                {t('dashboard.welcome', 'Hello, {{name}}', { name: user.first_name })}
              </Title>
              <Text type="secondary" style={{ fontSize: 16 }}>
                {t('dashboard.subtitle', 'Manage your health journey')}
              </Text>
            </div>
            <Button type="primary" size="large" icon={<IconCalendar size={20} />} href="/search">
              {t('dashboard.book_new', 'Book Appointment')}
            </Button>
          </Flex>
        </div>
      </div>

      <div style={{ maxWidth: 1000, margin: '32px auto', padding: '0 24px' }}>
        <Row gutter={24}>
          <Col xs={24} md={16}>
            <Title level={4} style={{ marginBottom: 16 }}>{t('dashboard.appointments', 'Your Appointments')}</Title>
            <Tabs defaultActiveKey="upcoming" items={items} />
          </Col>

          <Col xs={24} md={8}>
            <Flex vertical gap="large">
              <Card title={t('dashboard.quick_actions', 'Quick Actions')} bordered={false} style={{ borderRadius: 12 }}>
                <Flex vertical gap="small">
                  <Button block icon={<IconFileText size={16} />} style={{ textAlign: 'left' }}>
                    {t('dashboard.medical_records', 'Medical Records')}
                  </Button>
                  <Button block icon={<IconUser size={16} />} style={{ textAlign: 'left' }} href="/profile">
                    {t('dashboard.profile', 'Edit Profile')}
                  </Button>
                </Flex>
              </Card>

              <Card bordered={false} style={{ borderRadius: 12, background: 'linear-gradient(135deg, #0f766e, #0d9488)', color: 'white' }}>
                <Title level={5} style={{ color: 'white', marginTop: 0 }}>{t('dashboard.get_app', 'Get the Medic App')}</Title>
                <Text style={{ color: 'rgba(255,255,255,0.9)', marginBottom: 16, display: 'block' }}>
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
    case 'cancelled':
      return 'error'
    case 'completed':
      return 'default'
    default:
      return 'default'
  }
}

export default PatientDashboard
