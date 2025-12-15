import {
  Button as DesktopButton,
  Card as DesktopCard,
  Col,
  Row,
  Statistic,
  Typography,
  Space,
  Avatar,
  List as DesktopList,
  Flex,
  Tag
} from 'antd'
import {
  IconCalendar,
  IconCheck,
  IconClock,
  IconVideo,
  IconStar,
  IconUser
} from '@tabler/icons-react'
import { Link, router } from '@inertiajs/react'
import { format } from 'date-fns'
import { useTranslation } from 'react-i18next'
import { useIsMobile } from '@/lib/device'

import type { AppPageProps } from '@/types/app'

// Mobile imports
import { Card as MobileCard, List, Button as MobileButton, Tag as MobileTag, Empty } from 'antd-mobile'
import { CalendarOutline, CheckOutline, StarOutline, ClockCircleOutline } from 'antd-mobile-icons'

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

// =============================================================================
// MOBILE DOCTOR DASHBOARD
// =============================================================================

function MobileDoctorDashboard({ doctor, todayAppointments, pendingCount, upcomingCount }: Omit<PageProps, 'app' | 'auth'>) {
  const { t } = useTranslation('default')

  return (
    <div style={{ padding: 16, paddingBottom: 80 }}>
      {/* Header */}
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, margin: '0 0 4px' }}>
          {t('doctor.dashboard.title', 'Dashboard')}
        </h2>
        <p style={{ color: '#666', margin: 0, fontSize: 14 }}>
          {t('doctor.dashboard.subtitle', 'Good morning, Dr. {{lastName}}', { lastName: doctor.lastName })}
        </p>
      </div>

      {/* Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 20 }}>
        <MobileStatCard
          icon={<CalendarOutline fontSize={20} />}
          label="Today"
          value={todayAppointments.length}
          color="#3b82f6"
          bg="#eff6ff"
        />
        <MobileStatCard
          icon={<CheckOutline fontSize={20} />}
          label="Pending"
          value={pendingCount}
          color="#eab308"
          bg="#fef9c3"
        />
        <MobileStatCard
          icon={<CalendarOutline fontSize={20} />}
          label="This Week"
          value={upcomingCount}
          color="#10b981"
          bg="#d1fae5"
        />
        <MobileStatCard
          icon={<StarOutline fontSize={20} />}
          label="Rating"
          value={doctor.rating ? doctor.rating.toFixed(1) : '—'}
          color="#f59e0b"
          bg="#fffbeb"
        />
      </div>

      {/* Today's Appointments */}
      <MobileCard title="Today's Schedule" style={{ borderRadius: 12, marginBottom: 16 }}>
        {todayAppointments.length === 0 ? (
          <Empty description="No appointments today" style={{ padding: 20 }} />
        ) : (
          <List>
            {todayAppointments.map((appt) => {
              const startsAt = new Date(appt.startsAt)
              return (
                <List.Item
                  key={appt.id}
                  description={
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                      <ClockCircleOutline fontSize={12} />
                      <span>{format(startsAt, 'p')}</span>
                      <MobileTag
                        color={appt.status === 'confirmed' ? 'success' : 'primary'}
                        fill="outline"
                        style={{ fontSize: 10 }}
                      >
                        {appt.status}
                      </MobileTag>
                    </div>
                  }
                  arrow={false}
                >
                  <span style={{ fontWeight: 500 }}>
                    {appt.patient.firstName} {appt.patient.lastName}
                  </span>
                  <span style={{ color: '#999', marginLeft: 8, fontSize: 13 }}>
                    {appt.appointmentType === 'telemedicine' ? '📹 Video' : '🏥 In-person'}
                  </span>
                </List.Item>
              )
            })}
          </List>
        )}
      </MobileCard>

      {/* Quick Actions */}
      <MobileCard title="Quick Actions" style={{ borderRadius: 12 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <MobileButton
            block
            size="large"
            onClick={() => router.visit('/doctor/schedule')}
            style={{ '--border-radius': '8px' }}
          >
            Manage Availability
          </MobileButton>
          <MobileButton
            block
            size="large"
            onClick={() => router.visit('/dashboard/doctor/profile')}
            style={{ '--border-radius': '8px' }}
          >
            Edit Profile
          </MobileButton>
        </div>
      </MobileCard>
    </div>
  )
}

function MobileStatCard({ icon, label, value, color, bg }: { icon: React.ReactNode; label: string; value: number | string; color: string; bg: string }) {
  return (
    <div style={{
      backgroundColor: '#fff',
      borderRadius: 12,
      padding: 16,
      border: '1px solid #f0f0f0'
    }}>
      <div style={{
        width: 36,
        height: 36,
        borderRadius: '50%',
        backgroundColor: bg,
        color: color,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 8
      }}>
        {icon}
      </div>
      <div style={{ fontSize: 11, color: '#999', textTransform: 'uppercase', fontWeight: 500 }}>{label}</div>
      <div style={{ fontSize: 22, fontWeight: 700 }}>{value}</div>
    </div>
  )
}

// =============================================================================
// DESKTOP DOCTOR DASHBOARD (Original)
// =============================================================================

function DesktopDoctorDashboard({ doctor, todayAppointments, pendingCount, upcomingCount }: Omit<PageProps, 'app' | 'auth'>) {
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
          <DesktopButton type="default">
            {t('doctor.dashboard.edit_profile', 'Edit profile')}
          </DesktopButton>
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
          <DesktopCard
            title={<Title level={4} style={{ margin: 0 }}>{t('doctor.dashboard.today_schedule', "Today's schedule")}</Title>}
            bordered
            style={{ height: '100%', borderRadius: 12 }}
          >
            {todayAppointments.length === 0 ? (
              <div style={{ padding: '40px 0', textAlign: 'center' }}>
                <Text type="secondary">{t('doctor.dashboard.no_appointments', 'No appointments today')}</Text>
              </div>
            ) : (
              <DesktopList
                itemLayout="horizontal"
                dataSource={todayAppointments}
                renderItem={(appt) => <AppointmentRow appointment={appt} />}
              />
            )}
          </DesktopCard>
        </Col>

        <Col xs={24} lg={8}>
          <DesktopCard
            title={<Title level={4} style={{ margin: 0 }}>{t('doctor.dashboard.quick_actions', 'Quick actions')}</Title>}
            bordered
            style={{ height: '100%', borderRadius: 12 }}
          >
            <Flex vertical gap="middle">
              <Link href="/doctor/schedule" style={{ display: 'block' }}>
                <DesktopButton block size="large">
                  {t('doctor.dashboard.manage_schedule', 'Manage availability')}
                </DesktopButton>
              </Link>
              <Link href="/dashboard/doctor/profile" style={{ display: 'block' }}>
                <DesktopButton block size="large">
                  {t('doctor.dashboard.edit_profile', 'Edit profile')}
                </DesktopButton>
              </Link>
              <DesktopButton block size="large" disabled>
                {t('doctor.dashboard.analytics', 'Analytics (coming soon)')}
              </DesktopButton>
            </Flex>
          </DesktopCard>
        </Col>
      </Row>
    </div>
  )
}

const StatCard = ({ icon, label, value, subtitle, color, bg }: { icon: React.ReactNode; label: string; value: number | string; subtitle: string, color: string, bg: string }) => (
  <DesktopCard bordered style={{ borderRadius: 12, height: '100%' }} styles={{ body: { padding: 20 } }}>
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
  </DesktopCard>
)

const AppointmentRow = ({ appointment }: { appointment: Appointment }) => {
  const { t } = useTranslation('default')
  const startsAt = new Date(appointment.startsAt)
  const startText = format(startsAt, 'p')

  return (
    <DesktopCard bordered={false} style={{ marginBottom: 16, border: '1px solid #f0f0f0', borderRadius: 8 }} styles={{ body: { padding: 16 } }}>
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
          {appointment.notes && <Text style={{ fontSize: 14, fontStyle: 'italic' }}>"{appointment.notes}"</Text>}
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
    </DesktopCard>
  )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

const DoctorDashboardPage = ({ app, auth, doctor, todayAppointments, pendingCount, upcomingCount }: PageProps) => {
  const isMobile = useIsMobile()

  if (isMobile) {
    return <MobileDoctorDashboard doctor={doctor} todayAppointments={todayAppointments} pendingCount={pendingCount} upcomingCount={upcomingCount} />
  }

  return <DesktopDoctorDashboard doctor={doctor} todayAppointments={todayAppointments} pendingCount={pendingCount} upcomingCount={upcomingCount} />
}

export default DoctorDashboardPage
