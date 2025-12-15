import { Card as DesktopCard, Space, Typography, Tag, Button as DesktopButton } from 'antd'
import { useTranslation } from 'react-i18next'
import { router } from '@inertiajs/react'
import { useIsMobile } from '@/lib/device'

import type { AppPageProps } from '@/types/app'

// Mobile imports
import { List, Card as MobileCard, Button as MobileButton, Tag as MobileTag, Empty } from 'antd-mobile'
import { BellOutline } from 'antd-mobile-icons'

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

// =============================================================================
// MOBILE NOTIFICATIONS
// =============================================================================

function MobileNotificationsPage({ app, notifications, unread }: { app: any; notifications: Notification[]; unread: number }) {
  const { t } = useTranslation('default')

  const formatInsertedAt = (notification: Notification) => {
    const raw = notification.insertedAt ?? notification.inserted_at
    if (!raw) return ''
    const date = new Date(raw)
    if (Number.isNaN(date.valueOf())) return ''
    return date.toLocaleString(app.locale)
  }

  return (
    <div style={{ padding: 16, paddingBottom: 80 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 20 }}>
        <div>
          <h2 style={{ fontSize: 22, fontWeight: 700, margin: '0 0 4px' }}>{t('notifications.title', 'Notifications')}</h2>
          <p style={{ color: '#666', margin: 0, fontSize: 14 }}>{t('notifications.subtitle', 'Stay up to date')}</p>
        </div>
        {unread > 0 && (
          <MobileButton size="small" onClick={() => router.post('/notifications/mark_all')}>
            {t('notifications.mark_all', 'Mark all read')}
          </MobileButton>
        )}
      </div>

      {notifications.length === 0 ? (
        <Empty
          style={{ padding: '60px 0' }}
          description={t('notifications.empty', 'No notifications yet')}
          image={<BellOutline style={{ fontSize: 48, color: '#ccc' }} />}
        />
      ) : (
        <List>
          {notifications.map((notification) => {
            const isUnread = !(notification.readAt ?? notification.read_at)
            return (
              <List.Item
                key={notification.id}
                description={
                  <div>
                    <div style={{ marginBottom: 4 }}>{notification.message}</div>
                    <div style={{ fontSize: 12, color: '#999' }}>{formatInsertedAt(notification)}</div>
                  </div>
                }
                extra={isUnread && <MobileTag color="success">New</MobileTag>}
                onClick={() => {
                  if (isUnread) {
                    router.post(`/notifications/${notification.id}/read`)
                  }
                }}
                arrow={false}
                style={{
                  backgroundColor: isUnread ? '#f6ffed' : 'transparent',
                  borderRadius: 8,
                  marginBottom: 8
                }}
              >
                <span style={{ fontWeight: isUnread ? 600 : 400 }}>{notification.title}</span>
              </List.Item>
            )
          })}
        </List>
      )}
    </div>
  )
}

// =============================================================================
// DESKTOP NOTIFICATIONS (Original)
// =============================================================================

function DesktopNotificationsPage({ app, notifications, unread }: { app: any; notifications: Notification[]; unread: number }) {
  const { t } = useTranslation('default')

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
          <DesktopButton onClick={() => router.post('/notifications/mark_all')}>
            {t('notifications.mark_all', 'Mark all read')}
          </DesktopButton>
        )}
      </Space>

      {notifications.length === 0 ? (
        <DesktopCard bordered>
          <Typography.Text type="secondary">
            {t('notifications.empty', 'No notifications yet')}
          </Typography.Text>
        </DesktopCard>
      ) : (
        notifications.map((notification) => (
          <DesktopCard key={notification.id} bordered style={{ borderRadius: 12 }}>
            <Space direction="vertical" size="small" style={{ width: '100%' }}>
              <Space align="center" style={{ width: '100%', justifyContent: 'space-between' }}>
                <Typography.Text strong>{notification.title}</Typography.Text>
                {!(notification.readAt ?? notification.read_at) ? (
                  <Space size="small">
                    <Tag color="green">{t('notifications.new', 'New')}</Tag>
                    <DesktopButton
                      type="link"
                      size="small"
                      onClick={() => router.post(`/notifications/${notification.id}/read`)}
                    >
                      {t('notifications.mark_read', 'Mark read')}
                    </DesktopButton>
                  </Space>
                ) : null}
              </Space>
              <Typography.Text>{notification.message}</Typography.Text>
              <Typography.Text type="secondary" style={{ fontSize: 12 }}>
                {formatInsertedAt(notification)}
              </Typography.Text>
            </Space>
          </DesktopCard>
        ))
      )}
    </Space>
  )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

const NotificationsIndex = ({ app, auth, notifications, unreadCount, unread_count }: PageProps) => {
  const isMobile = useIsMobile()
  const unread = typeof unreadCount === 'number' ? unreadCount : (typeof unread_count === 'number' ? unread_count : 0)

  if (isMobile) {
    return <MobileNotificationsPage app={app} notifications={notifications} unread={unread} />
  }

  return <DesktopNotificationsPage app={app} notifications={notifications} unread={unread} />
}

export default NotificationsIndex
