import { Badge, Button, Card, Group, Stack, Text, Title } from '@mantine/core'
import { format } from 'date-fns'
import { useTranslation } from 'react-i18next'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

type PageProps = AppPageProps<{
  appointment: {
    id: string
    starts_at: string
    ends_at: string
    status: string
    notes?: string | null
    doctor: {
      id: string
      first_name: string
      last_name: string
      specialty?: string | null
    }
    patient: {
      id: string
      first_name: string
      last_name: string
    }
  }
}>

const AppointmentDetailPage = ({ app, auth, appointment }: PageProps) => {
  const { t } = useTranslation('default')
  const startsAt = new Date(appointment.starts_at)
  const endsAt = new Date(appointment.ends_at)

  return (
    <PublicLayout app={app} auth={auth}>
      <Stack gap="lg">
        <Title order={2}>{t('appointment.title', 'Appointment details')}</Title>

        <Card padding="xl" radius="lg" withBorder>
          <Stack gap="md">
            <Group justify="space-between">
              <div>
                <Text fw={600}>
                  Dr. {appointment.doctor.first_name} {appointment.doctor.last_name}
                </Text>
                <Text c="dimmed" size="sm">
                  {appointment.doctor.specialty}
                </Text>
              </div>
              <Badge>{appointment.status}</Badge>
            </Group>

            <Group gap="xl">
              <div>
                <Text size="sm" c="dimmed">
                  {t('appointment.labels.date', 'Date')}
                </Text>
                <Text fw={600}>{format(startsAt, 'PPPP')}</Text>
              </div>
              <div>
                <Text size="sm" c="dimmed">
                  {t('appointment.labels.time', 'Time')}
                </Text>
                <Text fw={600}>
                  {format(startsAt, 'p')} - {format(endsAt, 'p')}
                </Text>
              </div>
            </Group>

            {appointment.notes && (
              <div>
                <Text size="sm" c="dimmed">
                  {t('appointment.labels.notes', 'Notes')}
                </Text>
                <Text>{appointment.notes}</Text>
              </div>
            )}

            <Group gap="sm">
              <Button>{t('appointment.cta.reschedule', 'Reschedule')}</Button>
              <Button variant="light" color="red">
                {t('appointment.cta.cancel', 'Cancel appointment')}
              </Button>
            </Group>
          </Stack>
        </Card>
      </Stack>
    </PublicLayout>
  )
}

export default AppointmentDetailPage
