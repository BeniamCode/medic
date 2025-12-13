import { Card, Space, Typography, Tag, Button } from 'antd'
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
      <Space direction="vertical" size="large" style={{ maxWidth: 640, width: '100%', margin: '0 auto' }}>
        <Space align="start" style={{ width: '100%', justifyContent: 'space-between' }}>
          <div>
            <Typography.Title level={3}>{t('notifications.title', 'Notifications')}</Typography.Title>
            <Typography.Text type="secondary">
              {t('notifications.subtitle', 'Stay up to date with your practice')}
            </Typography.Text>
          </div>
          {unread_count > 0 && (
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
                  {!notification.read_at && <Tag color="green">{t('notifications.new', 'New')}</Tag>}
                </Space>
                <Typography.Text>{notification.message}</Typography.Text>
                <Typography.Text type="secondary" style={{ fontSize: 12 }}>
                  {new Date(notification.inserted_at).toLocaleString(app.locale)}
                </Typography.Text>
              </Space>
            </Card>
          ))
        )}
      </Space>
    </PublicLayout>
  )
}

export default NotificationsIndex
