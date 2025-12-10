import { Badge, Button } from '@mantine/core'
import { IconBell } from '@tabler/icons-react'
import { usePage, router } from '@inertiajs/react'
import type { SharedAppProps } from '@/types/app'

export const NotificationBell = () => {
  const page = usePage<SharedAppProps & { unread_count?: number }>()
  const unread = page.props.app?.unread_count || 0

  return (
    <Button variant="subtle" leftSection={<IconBell size={16} />} onClick={() => router.get('/notifications')}>
      {unread > 0 && <Badge color="red">{unread > 9 ? '9+' : unread}</Badge>}
    </Button>
  )
}
