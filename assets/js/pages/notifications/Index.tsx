import { Badge, Button, Card, Group, Stack, Text, Title } from '@mantine/core'
import { useTranslation } from 'react-i18next'
import { router } from '@inertiajs/react'

import { PublicLayout } from '@/layouts/PublicLayout'
import type { AppPageProps } from '@/types/app'

type Notification = {
  id: string
  title: string
  message: string
  read_at: string | null
  inserted_at: string
}

type PageProps = AppPageProps<{ notifications: Notification[]; unread_count: number }>

const NotificationsIndex = ({ app, auth, notifications, unread_count }: PageProps) => {
  const { t } = useTranslation('default')

  return (
    <PublicLayout app={app} auth={auth}>
      <Stack gap="lg" maw={600} mx="auto">
        <Group justify="space-between">
          <div>
            <Title order={2}>{t('notifications.title', 'Notifications')}</Title>
            <Text c="dimmed">{t('notifications.subtitle', 'Stay up to date with your practice')}</Text>
          </div>
          {unread_count > 0 && (
            <Button variant="light" onClick={() => router.post('/notifications/mark_all')}>
              {t('notifications.mark_all', 'Mark all read')}
            </Button>
          )}
        </Group>

        {notifications.length === 0 ? (
          <Card withBorder padding="xl">
            <Text c="dimmed">{t('notifications.empty', 'No notifications yet')}</Text>
          </Card>
        ) : (
          notifications.map((notification) => (
            <Card key={notification.id} withBorder padding="lg" radius="md" shadow="sm">
              <Stack gap="xs">
                <Group justify="space-between">
                  <Text fw={600}>{notification.title}</Text>
                  {!notification.read_at && <Badge color="green">{t('notifications.new', 'New')}</Badge>}
                </Group>
                <Text>{notification.message}</Text>
                <Text size="xs" c="dimmed">
                  {new Date(notification.inserted_at).toLocaleString(app.locale)}
                </Text>
              </Stack>
            </Card>
          ))
        )}
      </Stack>
    </PublicLayout>
  )
}

export default NotificationsIndex
