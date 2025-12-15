import { Card as DesktopCard, Space, Typography, Tag, Button as DesktopButton, Tabs } from 'antd'
import { useTranslation } from 'react-i18next'
import { router } from '@inertiajs/react'
import { useIsMobile } from '@/lib/device'
import { useState } from 'react'

import type { AppPageProps } from '@/types/app'

// Mobile imports
import { List, Card as MobileCard, Button as MobileButton, Tag as MobileTag, Empty, Tabs as MobileTabs } from 'antd-mobile'
import { BellOutline } from 'antd-mobile-icons'

type NotificationCategory = 'confirmed' | 'request' | 'cancelled' | 'other'

type Notification = {
  id: string
  title: string
  message: string
  readAt?: string | null
  read_at?: string | null
  insertedAt?: string
  inserted_at?: string
  template?: string
  category?: NotificationCategory
}

type PageProps = AppPageProps<{ notifications: Notification[]; unreadCount?: number; unread_count?: number }>

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

function getNotificationColor(category?: NotificationCategory): string {
  switch (category) {
    case 'confirmed':
      return '#52c41a' // green
    case 'request':
      return '#1890ff' // blue
    case 'cancelled':
      return '#ff4d4f' // red
    default:
      return '#d9d9d9' // gray
  }
}

function groupNotificationsByDate(notifications: Notification[], locale: string) {
  const now = new Date()
  const today = new Date(now.getFullYear(), now.getMonth(), now.getDate())
  const yesterday = new Date(today)
  yesterday.setDate(yesterday.getDate() - 1)
  const weekAgo = new Date(today)
  weekAgo.setDate(weekAgo.getDate() - 7)

  const groups: { label: string; notifications: Notification[] }[] = [
    { label: 'Today', notifications: [] },
    { label: 'Yesterday', notifications: [] },
    { label: 'This Week', notifications: [] },
    { label: 'Earlier', notifications: [] },
  ]

  notifications.forEach((notification) => {
    const raw = notification.insertedAt ?? notification.inserted_at
    if (!raw) {
      groups[3].notifications.push(notification)
      return
    }

    const date = new Date(raw)
    if (Number.isNaN(date.valueOf())) {
      groups[3].notifications.push(notification)
      return
    }

    const notifDate = new Date(date.getFullYear(), date.getMonth(), date.getDate())

    if (notifDate.getTime() === today.getTime()) {
      groups[0].notifications.push(notification)
    } else if (notifDate.getTime() === yesterday.getTime()) {
      groups[1].notifications.push(notification)
    } else if (notifDate >= weekAgo) {
      groups[2].notifications.push(notification)
    } else {
      groups[3].notifications.push(notification)
    }
  })

  return groups.filter((group) => group.notifications.length > 0)
}

// =============================================================================
// MOBILE NOTIFICATIONS
// =============================================================================

function MobileNotificationsPage({ app, notifications, unread }: { app: any; notifications: Notification[]; unread: number }) {
  const { t } = useTranslation('default')
  const [activeFilter, setActiveFilter] = useState<'all' | NotificationCategory>('all')

  const formatInsertedAt = (notification: Notification) => {
    const raw = notification.insertedAt ?? notification.inserted_at
    if (!raw) return ''
    const date = new Date(raw)
    if (Number.isNaN(date.valueOf())) return ''
    return date.toLocaleString(app.locale)
  }

  const filteredNotifications =
    activeFilter === 'all' ? notifications : notifications.filter((n) => n.category === activeFilter)

  const groupedNotifications = groupNotificationsByDate(filteredNotifications, app.locale)

  return (
    <div style={{ paddingBottom: 80 }}>
      <div style={{ padding: '16px 16px 12px', backgroundColor: '#fff', borderBottom: '1px solid #f0f0f0' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
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

        <MobileTabs
          activeKey={activeFilter}
          onChange={(key) => setActiveFilter(key as any)}
          style={{ '--active-line-color': '#1890ff' } as any}
        >
          <MobileTabs.Tab title="All" key="all" />
          <MobileTabs.Tab title="Confirmed" key="confirmed" />
          <MobileTabs.Tab title="Requests" key="request" />
          <MobileTabs.Tab title="Cancelled" key="cancelled" />
        </MobileTabs>
      </div>

      {filteredNotifications.length === 0 ? (
        <Empty
          style={{ padding: '60px 0' }}
          description={t('notifications.empty', 'No notifications yet')}
          image={<BellOutline style={{ fontSize: 48, color: '#ccc' }} />}
        />
      ) : (
        <div style={{ padding: '0 16px' }}>
          {groupedNotifications.map((group, groupIdx) => (
            <div key={groupIdx}>
              <div style={{ padding: '16px 0 8px', fontSize: 13, fontWeight: 600, color: '#999', textTransform: 'uppercase' }}>
                {group.label}
              </div>
              <List style={{ '--border-inner': 'none', '--border-top': 'none', '--border-bottom': 'none' } as any}>
                {group.notifications.map((notification) => {
                  const isUnread = !(notification.readAt ?? notification.read_at)
                  const color = getNotificationColor(notification.category)

                  return (
                    <List.Item
                      key={notification.id}
                      description={
                        <div>
                          <div style={{ marginBottom: 4 }}>{notification.message}</div>
                          <div style={{ fontSize: 12, color: '#999' }}>{formatInsertedAt(notification)}</div>
                        </div>
                      }
                      extra={
                        isUnread ? (
                          <MobileButton
                            size="mini"
                            fill="none"
                            onClick={(e) => {
                              e.stopPropagation()
                              router.post(`/notifications/${notification.id}/read`)
                            }}
                          >
                            Mark read
                          </MobileButton>
                        ) : null
                      }
                      onClick={() => {
                        if (isUnread) {
                          router.post(`/notifications/${notification.id}/read`)
                        }
                      }}
                      arrow={false}
                      style={{
                        backgroundColor: isUnread ? '#fafafa' : 'transparent',
                        borderRadius: 8,
                        marginBottom: 12,
                        padding: 16,
                        borderLeft: `4px solid ${color}`,
                        boxShadow: '0 1px 2px rgba(0,0,0,0.05)',
                      }}
                    >
                      <span style={{ fontWeight: isUnread ? 600 : 400 }}>{notification.title}</span>
                    </List.Item>
                  )
                })}
              </List>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

// =============================================================================
// DESKTOP NOTIFICATIONS
// =============================================================================

function DesktopNotificationsPage({ app, notifications, unread }: { app: any; notifications: Notification[]; unread: number }) {
  const { t } = useTranslation('default')
  const [activeFilter, setActiveFilter] = useState<'all' | NotificationCategory>('all')

  const formatInsertedAt = (notification: Notification) => {
    const raw = notification.insertedAt ?? notification.inserted_at
    if (!raw) return ''
    const date = new Date(raw)
    if (Number.isNaN(date.valueOf())) return ''
    return date.toLocaleString(app.locale)
  }

  const filteredNotifications =
    activeFilter === 'all' ? notifications : notifications.filter((n) => n.category === activeFilter)

  const groupedNotifications = groupNotificationsByDate(filteredNotifications, app.locale)

  const filterItems = [
    { key: 'all', label: 'All' },
    { key: 'confirmed', label: 'Confirmed' },
    { key: 'request', label: 'Requests' },
    { key: 'cancelled', label: 'Cancelled' },
  ]

  return (
    <Space direction="vertical" size="large" style={{ maxWidth: 720, width: '100%', margin: '0 auto', padding: '24px 16px' }}>
      <Space align="start" style={{ width: '100%', justifyContent: 'space-between' }}>
        <div>
          <Typography.Title level={3} style={{ margin: '0 0 4px' }}>
            {t('notifications.title', 'Notifications')}
          </Typography.Title>
          <Typography.Text type="secondary">{t('notifications.subtitle', 'Stay up to date with your practice')}</Typography.Text>
        </div>
        {unread > 0 && (
          <DesktopButton onClick={() => router.post('/notifications/mark_all')}>
            {t('notifications.mark_all', 'Mark all read')}
          </DesktopButton>
        )}
      </Space>

      <Tabs activeKey={activeFilter} onChange={(key) => setActiveFilter(key as any)} items={filterItems} />

      {filteredNotifications.length === 0 ? (
        <DesktopCard bordered>
          <Typography.Text type="secondary">{t('notifications.empty', 'No notifications yet')}</Typography.Text>
        </DesktopCard>
      ) : (
        groupedNotifications.map((group, groupIdx) => (
          <div key={groupIdx}>
            <Typography.Title level={5} style={{ color: '#999', marginBottom: 12 }}>
              {group.label}
            </Typography.Title>
            <Space direction="vertical" size="middle" style={{ width: '100%' }}>
              {group.notifications.map((notification) => {
                const isUnread = !(notification.readAt ?? notification.read_at)
                const color = getNotificationColor(notification.category)

                return (
                  <DesktopCard
                    key={notification.id}
                    bordered
                    style={{
                      borderRadius: 12,
                      borderLeft: `4px solid ${color}`,
                      backgroundColor: isUnread ? '#fafafa' : '#fff',
                    }}
                    bodyStyle={{ padding: 20 }}
                  >
                    <Space direction="vertical" size="small" style={{ width: '100%' }}>
                      <Space align="center" style={{ width: '100%', justifyContent: 'space-between' }}>
                        <Typography.Text strong style={{ fontSize: 15 }}>
                          {notification.title}
                        </Typography.Text>
                        {isUnread && (
                          <DesktopButton
                            type="link"
                            size="small"
                            onClick={() => router.post(`/notifications/${notification.id}/read`)}
                          >
                            {t('notifications.mark_read', 'Mark read')}
                          </DesktopButton>
                        )}
                      </Space>
                      <Typography.Text>{notification.message}</Typography.Text>
                      <Typography.Text type="secondary" style={{ fontSize: 12 }}>
                        {formatInsertedAt(notification)}
                      </Typography.Text>
                    </Space>
                  </DesktopCard>
                )
              })}
            </Space>
          </div>
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
  const unread = typeof unreadCount === 'number' ? unreadCount : typeof unread_count === 'number' ? unread_count : 0

  if (isMobile) {
    return <MobileNotificationsPage app={app} notifications={notifications} unread={unread} />
  }

  return <DesktopNotificationsPage app={app} notifications={notifications} unread={unread} />
}

export default NotificationsIndex

