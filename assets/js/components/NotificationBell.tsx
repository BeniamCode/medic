import { Badge, Button, Dropdown, Empty, Typography, Space } from 'antd'
import { IconBell } from '@tabler/icons-react'
import { usePage, router } from '@inertiajs/react'
import type { SharedAppProps } from '@/types/app'
import { useState } from 'react'
import axios from 'axios'

type NotificationCategory = 'confirmed' | 'request' | 'cancelled' | 'other'

type Notification = {
  id: string
  title: string
  message: string
  read_at?: string | null
  inserted_at: string
  template?: string
  category?: NotificationCategory
}

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

function formatTimeAgo(dateString: string): string {
  const date = new Date(dateString)
  const now = new Date()
  const seconds = Math.floor((now.getTime() - date.getTime()) / 1000)

  if (seconds < 60) return 'just now'
  const minutes = Math.floor(seconds / 60)
  if (minutes < 60) return `${minutes}m ago`
  const hours = Math.floor(minutes / 60)
  if (hours < 24) return `${hours}h ago`
  const days = Math.floor(hours / 24)
  if (days < 7) return `${days}d ago`
  const weeks = Math.floor(days / 7)
  return `${weeks}w ago`
}

export const NotificationBell = () => {
  const page = usePage<SharedAppProps & { unread_count?: number }>()
  const unread = page.props.app?.unreadCount || 0
  const [notifications, setNotifications] = useState<Notification[]>([])
  const [loading, setLoading] = useState(false)
  const [open, setOpen] = useState(false)

  const fetchNotifications = async () => {
    if (notifications.length > 0) return // Already fetched

    setLoading(true)
    try {
      const response = await axios.get('/notifications/recent_unread')
      setNotifications(response.data.notifications || [])
    } catch (error) {
      console.error('Failed to fetch notifications:', error)
    } finally {
      setLoading(false)
    }
  }

  const handleMarkAsRead = async (notificationId: string) => {
    try {
      await axios.post(`/notifications/${notificationId}/read`)
      // Remove from list
      setNotifications(prev => prev.filter(n => n.id !== notificationId))
      // Close dropdown if no more notifications
      if (notifications.length <= 1) {
        setOpen(false)
      }
      // Reload page to update badge count
      router.reload({ only: ['app'] })
    } catch (error) {
      console.error('Failed to mark notification as read:', error)
    }
  }

  const dropdownContent = (
    <div style={{
      width: 360,
      maxHeight: 400,
      overflow: 'auto',
      borderRadius: 12,
      boxShadow: '0 6px 16px rgba(0,0,0,0.12)',
      position: 'relative'
    }}>
      {/* Speech bubble arrow */}
      <div style={{
        position: 'absolute',
        top: -6,
        right: 16,
        width: 12,
        height: 12,
        backgroundColor: '#fff',
        transform: 'rotate(45deg)',
        borderTop: '1px solid #f0f0f0',
        borderLeft: '1px solid #f0f0f0'
      }} />

      {loading ? (
        <div style={{ padding: 24, textAlign: 'center' }}>
          <Typography.Text type="secondary">Loading...</Typography.Text>
        </div>
      ) : notifications.length === 0 ? (
        <div style={{ padding: 24 }}>
          <Empty
            image={Empty.PRESENTED_IMAGE_SIMPLE}
            description={<Typography.Text type="secondary">No new notifications</Typography.Text>}
          />
        </div>
      ) : (
        <div>
          {notifications.map((notification) => {
            const color = getNotificationColor(notification.category)
            const timeAgo = formatTimeAgo(notification.inserted_at)

            return (
              <div
                key={notification.id}
                onClick={() => handleMarkAsRead(notification.id)}
                style={{
                  padding: '12px 16px',
                  borderBottom: '1px solid #f0f0f0',
                  cursor: 'pointer',
                  transition: 'background-color 0.2s',
                  backgroundColor: '#fff',
                }}
                onMouseEnter={(e) => (e.currentTarget.style.backgroundColor = '#fafafa')}
                onMouseLeave={(e) => (e.currentTarget.style.backgroundColor = '#fff')}
              >
                <Space align="start" style={{ width: '100%' }}>
                  <div
                    style={{
                      width: 8,
                      height: 8,
                      borderRadius: '50%',
                      backgroundColor: color,
                      marginTop: 6,
                      flexShrink: 0,
                    }}
                  />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <Typography.Text
                      strong
                      style={{
                        display: 'block',
                        fontSize: 13,
                        marginBottom: 4,
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                      }}
                    >
                      {notification.title}
                    </Typography.Text>
                    <Typography.Text
                      type="secondary"
                      style={{
                        display: 'block',
                        fontSize: 12,
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                      }}
                    >
                      {notification.message}
                    </Typography.Text>
                    <Typography.Text type="secondary" style={{ fontSize: 11 }}>
                      {timeAgo}
                    </Typography.Text>
                  </div>
                </Space>
              </div>
            )
          })}
        </div>
      )}

      <div
        style={{
          padding: '10px 16px',
          borderTop: '1px solid #f0f0f0',
          textAlign: 'center',
          backgroundColor: '#fafafa',
          borderBottomLeftRadius: 12,
          borderBottomRightRadius: 12,
        }}
      >
        <Button
          type="link"
          size="small"
          onClick={() => {
            setOpen(false)
            router.get('/notifications')
          }}
          style={{ padding: 0 }}
        >
          View All Notifications
        </Button>
      </div>
    </div>
  )

  return (
    <Dropdown
      open={open}
      onOpenChange={(visible) => {
        setOpen(visible)
        if (visible) {
          fetchNotifications()
        }
      }}
      dropdownRender={() => dropdownContent}
      trigger={['click']}
      placement="bottomRight"
      overlayStyle={{ paddingTop: 8 }}
    >
      <Button
        type="text"
        icon={
          <Badge count={unread} size="small" offset={[0, 0]}>
            <IconBell size={20} />
          </Badge>
        }
      />
    </Dropdown>
  )
}
