import { Badge, Button, Card, Group, Stack, Text, Title } from '@mantine/core'
import { IconCalendar, IconCheck, IconClock, IconVideo, IconStar } from '@tabler/icons-react'
import { Link } from '@inertiajs/react'
import { format } from 'date-fns'
import { useTranslation } from 'react-i18next'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

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
    <Stack gap="xl" p="xl">
      <Group justify="space-between">
        <div>
          <Title order={2}>{t('doctor.dashboard.title', 'Doctor Dashboard')}</Title>
          <Text c="dimmed">
            {t('doctor.dashboard.subtitle', 'Good morning, Dr. {{lastName}}', {
              lastName: doctor.lastName
            })}
          </Text>
        </div>
        <Button component={Link} href="/dashboard/doctor/profile">
          {t('doctor.dashboard.edit_profile', 'Edit profile')}
        </Button>
      </Group>

      <Group grow>
        <StatCard
          icon={<IconCalendar size={20} />}
          label={t('doctor.dashboard.stats.today', 'Today')}
          value={todayAppointments.length}
          subtitle={t('doctor.dashboard.stats.today_sub', 'appointments')}
        />
        <StatCard
          icon={<IconCheck size={20} />}
          label={t('doctor.dashboard.stats.pending', 'Pending requests')}
          value={pendingCount}
          subtitle={t('doctor.dashboard.stats.pending_sub', 'Action required')}
        />
        <StatCard
          icon={<IconCalendar size={20} />}
          label={t('doctor.dashboard.stats.week', 'Confirmed (week)')}
          value={upcomingCount}
          subtitle={t('doctor.dashboard.stats.week_sub', 'upcoming visits')}
        />
        <StatCard
          icon={<IconStar size={20} />}
          label={t('doctor.dashboard.stats.rating', 'Rating')}
          value={doctor.rating ? doctor.rating.toFixed(1) : '—'}
          subtitle={`${doctor.reviewCount || 0} ${t('doctor.dashboard.stats.reviews', 'reviews')}`}
        />
      </Group>

      <Group align="flex-start" grow>
        <Card withBorder padding="lg" radius="lg" style={{ flex: 2 }}>
          <Stack gap="md">
            <Title order={4}>{t('doctor.dashboard.today_schedule', "Today's schedule")}</Title>
            {todayAppointments.length === 0 ? (
              <Text c="dimmed">{t('doctor.dashboard.no_appointments', 'No appointments today')}</Text>
            ) : (
              todayAppointments.map((appt) => <AppointmentRow key={appt.id} appointment={appt} />)
            )}
          </Stack>
        </Card>

        <Card withBorder padding="lg" radius="lg" style={{ flex: 1 }}>
          <Stack gap="sm">
            <Title order={4}>{t('doctor.dashboard.quick_actions', 'Quick actions')}</Title>
            <Button component={Link} href="/doctor/schedule" variant="light">
              {t('doctor.dashboard.manage_schedule', 'Manage availability')}
            </Button>
            <Button component={Link} href="/dashboard/doctor/profile" variant="light">
              {t('doctor.dashboard.edit_profile', 'Edit profile')}
            </Button>
            <Button variant="light" disabled>
              {t('doctor.dashboard.analytics', 'Analytics (coming soon)')}
            </Button>
          </Stack>
        </Card>
      </Group>
    </Stack>
  )
}

const StatCard = ({ icon, label, value, subtitle }: { icon: React.ReactNode; label: string; value: number | string; subtitle: string }) => (
  <Card padding="md" radius="lg" withBorder>
    <Group gap="sm" align="center">
      <div className="rounded-full bg-blue-50 p-2 text-blue-600">{icon}</div>
      <div>
        <Text size="xs" c="dimmed">
          {label}
        </Text>
        <Text size="xl" fw={700} lh={1.2}>
          {value}
        </Text>
        <Text size="xs" c="dimmed">
          {subtitle}
        </Text>
      </div>
    </Group>
  </Card>
)

const AppointmentRow = ({ appointment }: { appointment: Appointment }) => {
  const { t } = useTranslation('default')
  const startsAt = new Date(appointment.startsAt)
  const startText = format(startsAt, 'p')

  return (
    <Card padding="md" radius="lg" withBorder>
      <Group justify="space-between" align="flex-start">
        <Stack gap={4}>
          <Text fw={600}>
            {appointment.patient.firstName} {appointment.patient.lastName}
          </Text>
          <Text size="sm" c="dimmed">
            {appointment.appointmentType === 'telemedicine'
              ? t('doctor.dashboard.telemed', 'Telemedicine')
              : t('doctor.dashboard.in_person', 'In-person')}
          </Text>
          {appointment.notes && <Text size="sm">“{appointment.notes}”</Text>}
        </Stack>
        <Stack align="flex-end" gap={4}>
          <Group gap="xs">
            <IconClock size={14} />
            <Text>{startText}</Text>
          </Group>
          <Badge>{appointment.status}</Badge>
        </Stack>
      </Group>
    </Card>
  )
}

export default DoctorDashboardPage
