type ReadyPayload = {
  unread_count?: number
  unreadCount?: number
}

type NotificationPayload = {
  notification: {
    id: string
    title: string
    message: string
    type: string
    inserted_at?: string
    insertedAt?: string
    resource_id?: string | null
    resourceId?: string | null
    resource_type?: string | null
    resourceType?: string | null
  }
  unread_count?: number
  unreadCount?: number
}

declare global {
  interface Window {
    __medicNotificationsStream?: {
      es: EventSource | null
      started: boolean
      start: () => void
      stop: () => void
    }
  }
}

function normalizeCount(payload: { unread_count?: number; unreadCount?: number } | null | undefined) {
  if (!payload) return null
  if (typeof payload.unreadCount === 'number') return payload.unreadCount
  if (typeof payload.unread_count === 'number') return payload.unread_count
  return null
}

export function ensureNotificationsStream() {
  if (window.__medicNotificationsStream) return window.__medicNotificationsStream

  const state = {
    es: null as EventSource | null,
    started: false,
    start() {
      if (state.es) return

      state.started = true
      const es = new EventSource('/notifications/stream')
      state.es = es

      es.addEventListener('ready', (ev) => {
        try {
          const payload: ReadyPayload = JSON.parse((ev as MessageEvent).data)
          const count = normalizeCount(payload)
          if (typeof count === 'number') {
            window.dispatchEvent(new CustomEvent('medic:notifications:unreadCount', { detail: { unreadCount: count } }))
          }
        } catch {
          // ignore
        }
      })

      es.addEventListener('new_notification', (ev) => {
        try {
          const payload: NotificationPayload = JSON.parse((ev as MessageEvent).data)
          const count = normalizeCount(payload)

          window.dispatchEvent(new CustomEvent('medic:notifications:new', { detail: payload.notification }))

          if (typeof count === 'number') {
            window.dispatchEvent(new CustomEvent('medic:notifications:unreadCount', { detail: { unreadCount: count } }))
          }
        } catch {
          // ignore
        }
      })

      es.addEventListener('unread_count', (ev) => {
        try {
          const payload: ReadyPayload = JSON.parse((ev as MessageEvent).data)
          const count = normalizeCount(payload)
          if (typeof count === 'number') {
            window.dispatchEvent(new CustomEvent('medic:notifications:unreadCount', { detail: { unreadCount: count } }))
          }
        } catch {
          // ignore
        }
      })

      es.onerror = () => {
        // Browser will retry automatically. If the server returns 401, it often loops.
        // If we appear to be logged out later, callers should call stop().
      }
    },
    stop() {
      state.started = false
      state.es?.close()
      state.es = null
    }
  }

  window.__medicNotificationsStream = state
  return state
}
