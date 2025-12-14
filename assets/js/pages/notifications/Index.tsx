import { Card, Space, Typography, Tag, Button } from 'antd'
import { useTranslation } from 'react-i18next'
import { router } from '@inertiajs/react'

import type { AppPageProps } from '@/types/app'

type Notification = {
  id: string
  title: string
  message: string
  readAt?: string | null
  read_at?: string | null
  insertedAt?: string
  inserted_at?: string
}

type PageProps = AppPageProps<{ notifications: Notification[]; unreadCount?: number; unread_count?: number }>

const NotificationsIndex = ({ app, auth, notifications, unreadCount, unread_count }: PageProps) => {
  const { t } = useTranslation('default')
  const unread = typeof unreadCount === 'number' ? unreadCount : (typeof unread_count === 'number' ? unread_count : 0)

  const formatInsertedAt = (notification: Notification) => {
    const raw = notification.insertedAt ?? notification.inserted_at
    if (!raw) return ''

    const date = new Date(raw)
    if (Number.isNaN(date.valueOf())) return ''
    return date.toLocaleString(app.locale)
  }

  return (
    <Space direction="vertical" size="large" style={{ maxWidth: 640, width: '100%', margin: '0 auto' }}>
      <Space align="start" style={{ width: '100%', justifyContent: 'space-between' }}>
        <div>
          <Typography.Title level={3}>{t('notifications.title', 'Notifications')}</Typography.Title>
          <Typography.Text type="secondary">
            {t('notifications.subtitle', 'Stay up to date with your practice')}
          </Typography.Text>
        </div>
        {unread > 0 && (
          <Button onClick={() => router.post('/notifications/mark_all')}>
            {t('notifications.mark_all', 'Mark all read')}
          </Button>
        )}
      </Space>

      {notifications.length === 0 ? (
        <Card bordered>
          <Typography.Text type="secondary">
            {t('notifications.empty', 'No notifications yet')}
          </Typography.Text>
        </Card>
      ) : (
        notifications.map((notification) => (
          <Card key={notification.id} bordered style={{ borderRadius: 12 }}>
            <Space direction="vertical" size="small" style={{ width: '100%' }}>
              <Space align="center" style={{ width: '100%', justifyContent: 'space-between' }}>
                <Typography.Text strong>{notification.title}</Typography.Text>
                {!(notification.readAt ?? notification.read_at) ? (
                  <Space size="small">
                    <Tag color="green">{t('notifications.new', 'New')}</Tag>
                    <Button
                      type="link"
                      size="small"
                      onClick={() => router.post(`/notifications/${notification.id}/read`)}
                    >
                      {t('notifications.mark_read', 'Mark read')}
                    </Button>
                  </Space>
                ) : null}
              </Space>
              <Typography.Text>{notification.message}</Typography.Text>
              <Typography.Text type="secondary" style={{ fontSize: 12 }}>
                {formatInsertedAt(notification)}
              </Typography.Text>
            </Space>
          </Card>
        ))
      )}
    </Space>
  )
}

export default NotificationsIndex
