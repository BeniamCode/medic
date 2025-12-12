import { Badge, Button } from 'antd'
import { IconBell } from '@tabler/icons-react'
import { usePage, router } from '@inertiajs/react'
import type { SharedAppProps } from '@/types/app'

export const NotificationBell = () => {
  const page = usePage<SharedAppProps & { unread_count?: number }>()
  const unread = page.props.app?.unread_count || 0

  return (
    <Button
      type="text"
      icon={
        <Badge count={unread} size="small" offset={[0, 0]}>
          <IconBell size={20} />
        </Badge>
      }
      onClick={() => router.get('/notifications')}
    />
  )
}
