import { Badge, Button, Card, Group, Stack, Text, Title } from '@mantine/core'
import { IconCalendar, IconCheck, IconClock, IconX } from '@tabler/icons-react'
import { Link } from '@inertiajs/react'
import { formatDistanceToNowStrict, parseISO } from 'date-fns'
import { useTranslation } from 'react-i18next'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

type Appointment = {
  id: string
  starts_at: string
  status: string
  doctor: {
    id: string
    first_name: string
    last_name: string
    specialty?: string | null
  }
}

type Stats = {
  upcoming: number
  completed: number
  cancelled: number
}

type PageProps = AppPageProps<{
  patient: { id: string; first_name: string; last_name: string }
  upcoming_appointments: Appointment[]
  past_appointments: Appointment[]
  stats: Stats
}>

const statusColor: Record<string, string> = {
  pending: 'yellow',
  confirmed: 'green',
  completed: 'blue',
  cancelled: 'red',
  no_show: 'gray'
}

const DashboardPage = ({ app, auth, patient, upcoming_appointments, past_appointments, stats }: PageProps) => {
  const { t } = useTranslation('default')

  return (
    <PublicLayout app={app} auth={auth}>
      <Stack gap="xl">
        <div>
          <Title order={2}>{t('dashboard.title', 'Welcome back')}, {patient.first_name}</Title>
          <Text c="dimmed">{t('dashboard.subtitle', 'Stay on top of your care plan')}</Text>
        </div>

        <Group grow>
          <StatCard icon={<IconCalendar size={20} />} label={t('dashboard.stats.upcoming', 'Upcoming')} value={stats.upcoming} />
          <StatCard icon={<IconCheck size={20} />} label={t('dashboard.stats.completed', 'Completed')} value={stats.completed} />
          <StatCard icon={<IconX size={20} />} label={t('dashboard.stats.cancelled', 'Cancelled')} value={stats.cancelled} />
        </Group>

        <Card shadow="sm" padding="lg" radius="lg" withBorder>
          <Group justify="space-between" align="center">
            <Title order={3}>{t('dashboard.upcoming.title', 'Upcoming appointments')}</Title>
            <Button component={Link} href="/search" variant="light">
              {t('dashboard.upcoming.cta', 'Book new visit')}
            </Button>
          </Group>
          <Stack gap="md" mt="md">
            {upcoming_appointments.length === 0 ? (
              <Text c="dimmed">{t('dashboard.upcoming.empty', 'No appointments scheduled')}</Text>
            ) : (
              upcoming_appointments.map((appt) => <AppointmentRow key={appt.id} appointment={appt} />)
            )}
          </Stack>
        </Card>

        {past_appointments.length > 0 && (
          <Card shadow="sm" padding="lg" radius="lg" withBorder>
            <Title order={3}>{t('dashboard.past.title', 'Recent history')}</Title>
            <Stack gap="md" mt="md">
              {past_appointments.map((appt) => (
                <AppointmentRow key={appt.id} appointment={appt} compact />
              ))}
            </Stack>
          </Card>
        )}
      </Stack>
    </PublicLayout>
  )
}

const StatCard = ({ icon, label, value }: { icon: React.ReactNode; label: string; value: number }) => (
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
      </div>
    </Group>
  </Card>
)

const AppointmentRow = ({ appointment }: { appointment: Appointment }) => {
  const { t } = useTranslation('default')
  const startsAt = parseISO(appointment.starts_at)
  const human = formatDistanceToNowStrict(startsAt, { addSuffix: true })

  return (
    <Card padding="md" radius="lg" withBorder>
      <Group justify="space-between" align="center">
        <Stack gap={4}>
          <Text fw={600}>
            Dr. {appointment.doctor.first_name} {appointment.doctor.last_name}
          </Text>
          <Text size="sm" c="dimmed">
            {appointment.doctor.specialty || t('dashboard.appt.general', 'General practice')}
          </Text>
          <Group gap="xs">
            <IconClock size={14} />
            <Text size="sm">{human}</Text>
          </Group>
        </Stack>
        <Group gap="sm">
          <Badge color={statusColor[appointment.status] || 'gray'}>{appointment.status}</Badge>
          <Button component={Link} href={`/appointments/${appointment.id}`} variant="light" size="sm">
            {t('dashboard.appt.view', 'View')}
          </Button>
        </Group>
      </Group>
    </Card>
  )
}

export default DashboardPage
