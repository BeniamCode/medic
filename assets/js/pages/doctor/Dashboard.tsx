import {
  Button,
  Card,
  Col,
  Row,
  Statistic,
  Table,
  Tag,
  Typography,
  Space,
  Avatar,
  List,
  Flex
} from 'antd'
import {
  IconCalendar,
  IconCheck,
  IconClock,
  IconVideo,
  IconStar,
  IconUser
} from '@tabler/icons-react'
import { Link } from '@inertiajs/react'
import { format } from 'date-fns'
import { useTranslation } from 'react-i18next'

import type { AppPageProps } from '@/types/app'

const { Title, Text } = Typography

type Appointment = {
  id: string
  startsAt: string
  durationMinutes: number
  notes?: string | null
  status: string
  appointmentType: string
  patient: {
    firstName: string
    lastName: string
  }
}

type PageProps = AppPageProps<{
  doctor: {
    id: string
    firstName: string
    lastName: string
    rating: number | null
    reviewCount: number | null
    verified: boolean
  }
  todayAppointments: Appointment[]
  pendingCount: number
  upcomingCount: number
}>

const DoctorDashboardPage = ({ app, auth, doctor, todayAppointments, pendingCount, upcomingCount }: PageProps) => {
  const { t } = useTranslation('default')

  return (
    <div style={{ padding: 24, maxWidth: 1200, margin: '0 auto' }}>
      <Flex justify="space-between" align="center" style={{ marginBottom: 32 }}>
        <div>
          <Title level={2} style={{ margin: 0 }}>{t('doctor.dashboard.title', 'Doctor Dashboard')}</Title>
          <Text type="secondary">
            {t('doctor.dashboard.subtitle', 'Good morning, Dr. {{lastName}}', {
              lastName: doctor.lastName
            })}
          </Text>
        </div>
        <Link href="/dashboard/doctor/profile">
          <Button type="default">
            {t('doctor.dashboard.edit_profile', 'Edit profile')}
          </Button>
        </Link>
      </Flex>

      <Row gutter={[16, 16]} style={{ marginBottom: 32 }}>
        <Col xs={24} sm={12} md={6}>
          <StatCard
            icon={<IconCalendar size={20} />}
            label={t('doctor.dashboard.stats.today', 'Today')}
            value={todayAppointments.length}
            subtitle={t('doctor.dashboard.stats.today_sub', 'appointments')}
            color="#3b82f6"
            bg="#eff6ff"
          />
        </Col>
        <Col xs={24} sm={12} md={6}>
          <StatCard
            icon={<IconCheck size={20} />}
            label={t('doctor.dashboard.stats.pending', 'Pending requests')}
            value={pendingCount}
            subtitle={t('doctor.dashboard.stats.pending_sub', 'Action required')}
            color="#eab308"
            bg="#fef9c3"
          />
        </Col>
        <Col xs={24} sm={12} md={6}>
          <StatCard
            icon={<IconCalendar size={20} />}
            label={t('doctor.dashboard.stats.week', 'Confirmed (week)')}
            value={upcomingCount}
            subtitle={t('doctor.dashboard.stats.week_sub', 'upcoming visits')}
            color="#10b981"
            bg="#d1fae5"
          />
        </Col>
        <Col xs={24} sm={12} md={6}>
          <StatCard
            icon={<IconStar size={20} />}
            label={t('doctor.dashboard.stats.rating', 'Rating')}
            value={doctor.rating ? doctor.rating.toFixed(1) : '—'}
            subtitle={`${doctor.reviewCount || 0} ${t('doctor.dashboard.stats.reviews', 'reviews')}`}
            color="#f59e0b"
            bg="#fffbeb"
          />
        </Col>
      </Row>

      <Row gutter={24}>
        <Col xs={24} lg={16}>
          <Card
            title={<Title level={4} style={{ margin: 0 }}>{t('doctor.dashboard.today_schedule', "Today's schedule")}</Title>}
            bordered
            style={{ height: '100%', borderRadius: 12 }}
          >
            {todayAppointments.length === 0 ? (
              <div style={{ padding: '40px 0', textAlign: 'center' }}>
                <Text type="secondary">{t('doctor.dashboard.no_appointments', 'No appointments today')}</Text>
              </div>
            ) : (
              <List
                itemLayout="horizontal"
                dataSource={todayAppointments}
                renderItem={(appt) => <AppointmentRow appointment={appt} />}
              />
            )}
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Card
            title={<Title level={4} style={{ margin: 0 }}>{t('doctor.dashboard.quick_actions', 'Quick actions')}</Title>}
            bordered
            style={{ height: '100%', borderRadius: 12 }}
          >
            <Flex vertical gap="middle">
              <Link href="/doctor/schedule" style={{ display: 'block' }}>
                <Button block size="large">
                  {t('doctor.dashboard.manage_schedule', 'Manage availability')}
                </Button>
              </Link>
              <Link href="/dashboard/doctor/profile" style={{ display: 'block' }}>
                <Button block size="large">
                  {t('doctor.dashboard.edit_profile', 'Edit profile')}
                </Button>
              </Link>
              <Button block size="large" disabled>
                {t('doctor.dashboard.analytics', 'Analytics (coming soon)')}
              </Button>
            </Flex>
          </Card>
        </Col>
      </Row>
    </div>
  )
}

const StatCard = ({ icon, label, value, subtitle, color, bg }: { icon: React.ReactNode; label: string; value: number | string; subtitle: string, color: string, bg: string }) => (
  <Card bordered style={{ borderRadius: 12, height: '100%' }} bodyStyle={{ padding: 20 }}>
    <Flex gap="middle" align="center">
      <div style={{
        borderRadius: '50%',
        backgroundColor: bg,
        color: color,
        padding: 12,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center'
      }}>
        {icon}
      </div>
      <div>
        <Text type="secondary" style={{ fontSize: 12, fontWeight: 500, textTransform: 'uppercase' }}>
          {label}
        </Text>
        <div style={{ fontSize: 24, fontWeight: 700, lineHeight: 1.2 }}>
          {value}
        </div>
        <Text type="secondary" style={{ fontSize: 12 }}>
          {subtitle}
        </Text>
      </div>
    </Flex>
  </Card>
)

const AppointmentRow = ({ appointment }: { appointment: Appointment }) => {
  const { t } = useTranslation('default')
  const startsAt = new Date(appointment.startsAt)
  const startText = format(startsAt, 'p')

  return (
    <Card bordered={false} style={{ marginBottom: 16, border: '1px solid #f0f0f0', borderRadius: 8 }} bodyStyle={{ padding: 16 }}>
      <Flex justify="space-between" align="flex-start">
        <Space direction="vertical" size={2}>
          <Text strong style={{ fontSize: 16 }}>
            {appointment.patient.firstName} {appointment.patient.lastName}
          </Text>
          <Text type="secondary" style={{ fontSize: 14 }}>
            {appointment.appointmentType === 'telemedicine'
              ? t('doctor.dashboard.telemed', 'Telemedicine')
              : t('doctor.dashboard.in_person', 'In-person')}
          </Text>
          {appointment.notes && <Text style={{ fontSize: 14, fontStyle: 'italic' }}>“{appointment.notes}”</Text>}
        </Space>

        <Flex vertical align="flex-end" gap={4}>
          <Space size={4} style={{ color: '#595959' }}>
            <IconClock size={14} />
            <Text>{startText}</Text>
          </Space>
          <Tag color={appointment.status === 'confirmed' ? 'green' : 'blue'}>
            {appointment.status.toUpperCase()}
          </Tag>
        </Flex>
      </Flex>
    </Card>
  )
}

export default DoctorDashboardPage
