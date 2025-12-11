import { Badge, Button, Card, Container, Grid, Group, SimpleGrid, Stack, Text, ThemeIcon, Timeline, Title, Avatar, ActionIcon } from '@mantine/core'
import { IconCalendar, IconCheck, IconClock, IconX, IconStethoscope, IconArrowRight, IconDotsVertical, IconCalendarEvent } from '@tabler/icons-react'
import { Link } from '@inertiajs/react'
import { formatDistanceToNowStrict, parseISO, format } from 'date-fns'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'

type Appointment = {
  id: string
  startsAt: string
  status: string
  doctor: {
    id: string
    firstName: string
    lastName: string
    specialtyName?: string | null
    profileImageUrl?: string | null
  }
}

type Stats = {
  upcoming: number
  completed: number
  cancelled: number
}

type PageProps = AppPageProps<{
  patient: { id: string; firstName: string; lastName: string }
  upcomingAppointments: Appointment[]
  pastAppointments: Appointment[]
  stats: Stats
}>

const statusColor: Record<string, string> = {
  pending: 'yellow',
  confirmed: 'green',
  completed: 'blue',
  cancelled: 'red',
  no_show: 'gray'
}

export default function DashboardPage({ app, auth, patient, upcomingAppointments, pastAppointments, stats }: PageProps) {
  const { t } = useTranslation('default')

  return (
    <Container size="xl" py="xl">
      <Group justify="space-between" mb="xl">
        <Stack gap={0}>
          <Title order={2}>Good morning, {patient.firstName}</Title>
          <Text c="dimmed">Here is your health overview for today.</Text>
        </Stack>
        <Button leftSection={<IconStethoscope size={20} />} component={Link} href="/search" variant="filled" color="teal">
          Find Specialist
        </Button>
      </Group>

      <SimpleGrid cols={{ base: 1, sm: 3 }} spacing="lg" mb={40}>
        <StatCard
          icon={IconCalendarEvent}
          color="blue"
          label="Upcoming Visits"
          value={stats.upcoming}
          desc="Scheduled appointments"
        />
        <StatCard
          icon={IconCheck}
          color="teal"
          label="Completed"
          value={stats.completed}
          desc="Past consultations"
        />
        <StatCard
          icon={IconX}
          color="red"
          label="Cancelled"
          value={stats.cancelled}
          desc="Missed or cancelled"
        />
      </SimpleGrid>

      <Grid gutter="xl">
        <Grid.Col span={{ base: 12, md: 8 }}>
          <Card withBorder radius="lg" padding="xl">
            <Group justify="space-between" mb="lg">
              <Title order={3}>Upcoming Appointments</Title>
              <ActionIcon variant="subtle" color="gray"><IconDotsVertical size={18} /></ActionIcon>
            </Group>

            {upcomingAppointments.length > 0 ? (
              <Stack gap="md">
                {upcomingAppointments.map(appt => (
                  <AppointmentCard key={appt.id} appointment={appt} />
                ))}
              </Stack>
            ) : (
              <Stack align="center" py={40} bg="gray.0" style={{ borderRadius: 12 }}>
                <ThemeIcon color="gray" variant="light" size={48} radius="xl">
                  <IconCalendar size={24} />
                </ThemeIcon>
                <Text fw={500} mt="sm">No upcoming appointments</Text>
                <Text size="sm" c="dimmed">Book a consultation to get started</Text>
                <Button component={Link} href="/search" variant="light" mt="xs">Book Now</Button>
              </Stack>
            )}
          </Card>
        </Grid.Col>

        <Grid.Col span={{ base: 12, md: 4 }}>
          <Card withBorder radius="lg" padding="xl">
            <Title order={4} mb="lg">Recent History</Title>
            <Timeline active={0} bulletSize={24} lineWidth={2}>
              {pastAppointments.slice(0, 5).map(appt => (
                <Timeline.Item
                  key={appt.id}
                  bullet={<IconCheck size={12} />}
                  title={`Dr. ${appt.doctor.lastName}`}
                  color={statusColor[appt.status]}
                >
                  <Text c="dimmed" size="xs" mt={4}>
                    {format(parseISO(appt.startsAt), 'MMM d, yyyy')}
                  </Text>
                  <Text size="xs" mt={4}>
                    {appt.status}
                  </Text>
                </Timeline.Item>
              ))}
              {pastAppointments.length === 0 && (
                <Text c="dimmed" size="sm">No past history.</Text>
              )}
            </Timeline>
          </Card>
        </Grid.Col>
      </Grid>
    </Container>
  )
}

function StatCard({ icon: Icon, label, value, color, desc }: any) {
  return (
    <Card withBorder radius="lg" padding="lg">
      <Group>
        <ThemeIcon size={48} radius="md" variant="light" color={color}>
          <Icon size={24} />
        </ThemeIcon>
        <div>
          <Text c="dimmed" size="xs" fw={700} tt="uppercase">{label}</Text>
          <Text fw={700} size="xl" lh={1}>{value}</Text>
          <Text c="dimmed" size="xs">{desc}</Text>
        </div>
      </Group>
    </Card>
  )
}

function AppointmentCard({ appointment }: { appointment: Appointment }) {
  const date = parseISO(appointment.startsAt)

  return (
    <Card withBorder radius="md" padding="md">
      <Group wrap="nowrap">
        <Stack align="center" gap={0} bg="teal.0" p="xs" style={{ borderRadius: 8, minWidth: 70 }}>
          <Text size="xs" c="teal" fw={700} tt="uppercase">{format(date, 'MMM')}</Text>
          <Text size="xl" fw={700} lh={1} c="teal">{format(date, 'd')}</Text>
        </Stack>

        <Group justify="space-between" w="100%" align="flex-start">
          <div>
            <Text fw={600}>Dr. {appointment.doctor.firstName} {appointment.doctor.lastName}</Text>
            <Text size="sm" c="dimmed">{appointment.doctor.specialtyName || 'General Practice'}</Text>
            <Group gap={6} mt={4}>
              <IconClock size={14} className="text-gray-500" />
              <Text size="xs" c="dimmed">{format(date, 'h:mm a')} ({formatDistanceToNowStrict(date, { addSuffix: true })})</Text>
            </Group>
          </div>
          <Stack align="flex-end" gap="xs">
            <Badge color={statusColor[appointment.status]}>{appointment.status}</Badge>
            <Button component={Link} href={`/appointments/${appointment.id}`} variant="default" size="xs">
              Manage
            </Button>
          </Stack>
        </Group>
      </Group>
    </Card>
  )
}
