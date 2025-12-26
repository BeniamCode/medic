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
  Tag,
  Input
} from 'antd'
import {
  IconCalendar,
  IconCheck,
  IconClock,
  IconVideo,
  IconStar,
  IconUser,
  IconSearch as IconSearchDesktop
} from '@tabler/icons-react'
import { Link, router } from '@inertiajs/react'
import { format } from 'date-fns'
import { enUS, el } from 'date-fns/locale'
import { useTranslation } from 'react-i18next'
import { useIsMobile } from '@/lib/device'

import type { AppPageProps } from '@/types/app'

// Mobile imports
import { Card as MobileCard, List, Button as MobileButton, Tag as MobileTag, Empty, SearchBar } from 'antd-mobile'
import { CalendarOutline, CheckOutline, StarOutline, ClockCircleOutline } from 'antd-mobile-icons'
import { useState } from 'react'

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
  myPatients: MyPatient[]
  activeTab: 'dashboard' | 'patients'
}>

type MyPatient = {
  id: string
  firstName: string
  lastName: string
  phone?: string
  age?: number
  profileImageUrl?: string
  visitCount: number
  lastVisit: string | null
  firstVisit: string | null
  hasContext: boolean
  tags?: string[]
}

const DATE_LOCALES: Record<string, any> = {
  en: enUS,
  el: el
}

// =============================================================================
// MY PATIENTS LIST - DESKTOP
// =============================================================================

function MyPatientsList({ patients }: { patients: MyPatient[] }) {
  const { t, i18n } = useTranslation('default')
  const dateLocale = DATE_LOCALES[i18n.language] || enUS
  const [searchText, setSearchText] = useState('')

  const filteredPatients = patients.filter(patient => {
    const fullName = `${patient.firstName || ''} ${patient.lastName || ''}`.toLowerCase()
    const phone = patient.phone || ''
    return fullName.includes(searchText.toLowerCase()) || phone.includes(searchText)
  })

  return (
    <DesktopCard
      title={<Title level={4} style={{ margin: 0 }}>{t('My Patients')}</Title>}
      extra={
        <Input
          placeholder={t('Search patients...')}
          prefix={<IconSearchDesktop size={16} />}
          style={{ width: 250 }}
          value={searchText}
          onChange={(e) => setSearchText(e.target.value)}
          allowClear
        />
      }
      bordered
      style={{ borderRadius: 12 }}
    >
      <DesktopList
        itemLayout="horizontal"
        dataSource={filteredPatients}
        pagination={{ pageSize: 10 }}
        locale={{ emptyText: t('No patients found') }}
        renderItem={(patient) => (
          <DesktopList.Item
            actions={[
              <DesktopButton type="text" key="notes" onClick={() => {
                // TODO: Implement notes modal
                console.log('Edit notes for patient:', patient.id)
              }}>
                {patient.hasContext ? t('Edit Notes') : t('Add Notes')}
              </DesktopButton>
            ]}
          >
            <DesktopList.Item.Meta
              avatar={
                patient.profileImageUrl ? (
                  <Avatar src={patient.profileImageUrl} />
                ) : (
                  <Avatar style={{ backgroundColor: '#0d9488' }}>{patient.firstName?.[0] || '?'}</Avatar>
                )
              }
              title={
                <Space>
                  <span style={{ fontWeight: 600 }}>{patient.firstName} {patient.lastName}</span>
                  {patient.age && <Tag color="blue">{patient.age} {t('years')}</Tag>}
                  {patient.tags && patient.tags.length > 0 && patient.tags.map(tag => (
                    <Tag key={tag} color="default">{tag}</Tag>
                  ))}
                </Space>
              }
              description={
                <Space direction="vertical" size={0}>
                  <Space split="|" size="small">
                    <Text type="secondary">{t('Seen {{count}} times', { count: patient.visitCount })}</Text>
                    {patient.lastVisit && (
                      <Text type="secondary">
                        {t('Last visit')}: {format(new Date(patient.lastVisit), 'P', { locale: dateLocale })}
                      </Text>
                    )}
                  </Space>
                  {patient.phone && (
                    <Text type="secondary" style={{ fontSize: 12 }}>📱 {patient.phone}</Text>
                  )}
                  {patient.firstVisit && (
                    <Text type="secondary" style={{ fontSize: 12 }}>
                      {t('First visit')}: {format(new Date(patient.firstVisit), 'P', { locale: dateLocale })}
                    </Text>
                  )}
                </Space>
              }
            />
          </DesktopList.Item>
        )}
      />
    </DesktopCard>
  )
}

// =============================================================================
// MY PATIENTS LIST - MOBILE
// =============================================================================

function MobileMyPatientsList({ patients }: { patients: MyPatient[] }) {
  const { t, i18n } = useTranslation('default')
  const dateLocale = DATE_LOCALES[i18n.language] || enUS
  const [searchText, setSearchText] = useState('')

  const filteredPatients = patients.filter(patient => {
    const fullName = `${patient.firstName || ''} ${patient.lastName || ''}`.toLowerCase()
    const phone = patient.phone || ''
    return fullName.includes(searchText.toLowerCase()) || phone.includes(searchText)
  })

  return (
    <div style={{ padding: 16, paddingBottom: 80 }}>
      <h2 style={{ fontSize: 22, fontWeight: 700, margin: '0 0 16px' }}>
        {t('My Patients')}
      </h2>

      <SearchBar
        placeholder={t('Search patients...')}
        value={searchText}
        onChange={setSearchText}
        style={{ marginBottom: 16 }}
      />

      <MobileCard style={{ borderRadius: 12 }}>
        {filteredPatients.length === 0 ? (
          <Empty description={t('No patients found')} style={{ padding: 20 }} />
        ) : (
          <List>
            {filteredPatients.map((patient) => (
              <List.Item
                key={patient.id}
                prefix={
                  patient.profileImageUrl ? (
                    <Avatar src={patient.profileImageUrl} />
                  ) : (
                    <Avatar style={{ backgroundColor: '#0d9488' }}>
                      {patient.firstName?.[0] || '?'}
                    </Avatar>
                  )
                }
                description={
                  <div style={{ fontSize: 12, color: '#999', marginTop: 4 }}>
                    <div>{t('Seen {{count}} times', { count: patient.visitCount })}</div>
                    {patient.phone && <div>📱 {patient.phone}</div>}
                    {patient.lastVisit && (
                      <div>
                        {t('Last visit')}: {format(new Date(patient.lastVisit), 'P', { locale: dateLocale })}
                      </div>
                    )}
                    {patient.firstVisit && (
                      <div style={{ fontSize: 11 }}>
                        {t('First visit')}: {format(new Date(patient.firstVisit), 'P', { locale: dateLocale })}
                      </div>
                    )}
                  </div>
                }
                arrow={false}
              >
                <div>
                  <div style={{ fontWeight: 500 }}>
                    {patient.firstName} {patient.lastName}
                    {patient.age && <span style={{ marginLeft: 8, color: '#999', fontSize: 13 }}>({patient.age})</span>}
                  </div>
                  {patient.tags && patient.tags.length > 0 && (
                    <div style={{ marginTop: 4 }}>
                      {patient.tags.map(tag => (
                        <MobileTag key={tag} color="default" style={{ fontSize: 10, marginRight: 4 }}>{tag}</MobileTag>
                      ))}
                    </div>
                  )}
                </div>
              </List.Item>
            ))}
          </List>
        )}
      </MobileCard>
    </div>
  )
}

// =============================================================================
// MOBILE DOCTOR DASHBOARD
// =============================================================================

function MobileDoctorDashboard({ doctor, todayAppointments, pendingCount, upcomingCount }: Omit<PageProps, 'app' | 'auth'>) {
  const { t, i18n } = useTranslation('default')
  const dateLocale = DATE_LOCALES[i18n.language] || enUS

  return (
    <div style={{ padding: 16, paddingBottom: 80 }}>
      {/* Header */}
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, margin: '0 0 4px' }}>
          {t('Dashboard')}
        </h2>
        <p style={{ color: '#666', margin: 0, fontSize: 14 }}>
          {t('Good morning, Dr. {{lastName}}', { lastName: doctor.lastName })}
        </p>
      </div>

      {/* Stats Grid */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 20 }}>
        <MobileStatCard
          icon={<CalendarOutline fontSize={20} />}
          label={t('Today')}
          value={todayAppointments.length}
          color="#3b82f6"
          bg="#eff6ff"
        />
        <MobileStatCard
          icon={<CheckOutline fontSize={20} />}
          label={t('Pending')}
          value={pendingCount}
          color="#eab308"
          bg="#fef9c3"
        />
        <MobileStatCard
          icon={<CalendarOutline fontSize={20} />}
          label={t('This Week')}
          value={upcomingCount}
          color="#10b981"
          bg="#d1fae5"
        />
        <MobileStatCard
          icon={<StarOutline fontSize={20} />}
          label={t('Rating')}
          value={doctor.rating ? doctor.rating.toFixed(1) : '—'}
          color="#f59e0b"
          bg="#fffbeb"
        />
      </div>

      {/* Today's Appointments */}
      <MobileCard title={t("Today's Schedule")} style={{ borderRadius: 12, marginBottom: 16 }}>
        {todayAppointments.length === 0 ? (
          <Empty description={t('No appointments today')} style={{ padding: 20 }} />
        ) : (
          <List>
            {todayAppointments.map((appt: Appointment) => {
              const startsAt = new Date(appt.startsAt)
              return (
                <List.Item
                  key={appt.id}
                  description={
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                      <ClockCircleOutline fontSize={12} />
                      <span>{format(startsAt, 'p', { locale: dateLocale })}</span>
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
                    {appt.appointmentType === 'telemedicine' ? `📹 ${t('Video')}` : `🏥 ${t('In-person')}`}
                  </span>
                </List.Item>
              )
            })}
          </List>
        )}
      </MobileCard>

      {/* Quick Actions */}
      <MobileCard title={t('Quick Actions')} style={{ borderRadius: 12 }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <MobileButton
            block
            size="large"
            onClick={() => router.visit('/doctor/schedule')}
            style={{ '--border-radius': '8px' }}
          >
            {t('Manage Availability')}
          </MobileButton>
          <MobileButton
            block
            size="large"
            onClick={() => router.visit('/dashboard/doctor/profile')}
            style={{ '--border-radius': '8px' }}
          >
            {t('Edit Profile')}
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

function DesktopDoctorDashboard({ doctor, todayAppointments, pendingCount, upcomingCount, myPatients, activeTab }: Omit<PageProps, 'app' | 'auth'>) {
  const { t, i18n } = useTranslation('default')

  if (activeTab === 'patients') {
    return (
      <div style={{ padding: 24, maxWidth: 1200, margin: '0 auto' }}>
        <MyPatientsList patients={myPatients} />
      </div>
    )
  }

  return (
    <div style={{ padding: 24, maxWidth: 1200, margin: '0 auto' }}>
      <Flex justify="space-between" align="center" style={{ marginBottom: 32 }}>
        <div>
          <Title level={2} style={{ margin: 0 }}>{t('Doctor Dashboard')}</Title>
          <Text type="secondary">
            {t('Good morning, Dr. {{lastName}}', {
              lastName: doctor.lastName
            })}
          </Text>
        </div>
        <Link href="/dashboard/doctor/profile">
          <DesktopButton type="default">
            {t('Edit Profile')}
          </DesktopButton>
        </Link>
      </Flex>

      <Row gutter={[16, 16]} style={{ marginBottom: 32 }}>
        <Col xs={24} sm={12} md={6}>
          <StatCard
            icon={<IconCalendar size={20} />}
            label={t('Today')}
            value={todayAppointments.length}
            subtitle={t('appointments')}
            color="#3b82f6"
            bg="#eff6ff"
          />
        </Col>
        <Col xs={24} sm={12} md={6}>
          <StatCard
            icon={<IconCheck size={20} />}
            label={t('Pending requests')}
            value={pendingCount}
            subtitle={t('Action required')}
            color="#eab308"
            bg="#fef9c3"
          />
        </Col>
        <Col xs={24} sm={12} md={6}>
          <StatCard
            icon={<IconCalendar size={20} />}
            label={t('Confirmed (week)')}
            value={upcomingCount}
            subtitle={t('upcoming visits')}
            color="#10b981"
            bg="#d1fae5"
          />
        </Col>
        <Col xs={24} sm={12} md={6}>
          <StatCard
            icon={<IconStar size={20} />}
            label={t('Rating')}
            value={doctor.rating ? doctor.rating.toFixed(1) : '—'}
            subtitle={`${doctor.reviewCount || 0} ${t('reviews')}`}
            color="#f59e0b"
            bg="#fffbeb"
          />
        </Col>
      </Row>

      <Row gutter={24}>
        <Col xs={24} lg={16}>
          <DesktopCard
            title={<Title level={4} style={{ margin: 0 }}>{t("Today's Schedule")}</Title>}
            bordered
            style={{ height: '100%', borderRadius: 12 }}
          >
            {todayAppointments.length === 0 ? (
              <div style={{ padding: '40px 0', textAlign: 'center' }}>
                <Text type="secondary">{t('No appointments today')}</Text>
              </div>
            ) : (
              <DesktopList
                itemLayout="horizontal"
                dataSource={todayAppointments}
                renderItem={(appt: Appointment) => <AppointmentRow appointment={appt} />}
              />
            )}
          </DesktopCard>
        </Col>

        <Col xs={24} lg={8}>
          <DesktopCard
            title={<Title level={4} style={{ margin: 0 }}>{t('Quick Actions')}</Title>}
            bordered
            style={{ height: '100%', borderRadius: 12 }}
          >
            <Flex vertical gap="middle">
              <Link href="/doctor/schedule" style={{ display: 'block' }}>
                <DesktopButton block size="large">
                  {t('Manage Availability')}
                </DesktopButton>
              </Link>
              <Link href="/dashboard/doctor/profile" style={{ display: 'block' }}>
                <DesktopButton block size="large">
                  {t('Edit Profile')}
                </DesktopButton>
              </Link>
              <DesktopButton block size="large" disabled>
                {t('Analytics (coming soon)')}
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
  const { t, i18n } = useTranslation('default')
  const dateLocale = DATE_LOCALES[i18n.language] || enUS
  const startsAt = new Date(appointment.startsAt)
  const startText = format(startsAt, 'p', { locale: dateLocale })

  return (
    <DesktopCard bordered={false} style={{ marginBottom: 16, border: '1px solid #f0f0f0', borderRadius: 8 }} styles={{ body: { padding: 16 } }}>
      <Flex justify="space-between" align="flex-start">
        <Space direction="vertical" size={2}>
          <Text strong style={{ fontSize: 16 }}>
            {appointment.patient.firstName} {appointment.patient.lastName}
          </Text>
          <Text type="secondary" style={{ fontSize: 14 }}>
            {appointment.appointmentType === 'telemedicine'
              ? t('Telemedicine')
              : t('In-person')}
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

const DoctorDashboardPage = ({ app, auth, doctor, todayAppointments, pendingCount, upcomingCount, myPatients, activeTab }: PageProps) => {
  const isMobile = useIsMobile()

  // Mobile: Show patients tab when activeTab is 'patients'
  if (isMobile && activeTab === 'patients') {
    return <MobileMyPatientsList patients={myPatients} />
  }

  if (isMobile) {
    return <MobileDoctorDashboard doctor={doctor} todayAppointments={todayAppointments} pendingCount={pendingCount} upcomingCount={upcomingCount} myPatients={myPatients} activeTab={activeTab} />
  }

  return <DesktopDoctorDashboard doctor={doctor} todayAppointments={todayAppointments} pendingCount={pendingCount} upcomingCount={upcomingCount} myPatients={myPatients} activeTab={activeTab as 'dashboard' | 'patients'} />
}

export default DoctorDashboardPage
