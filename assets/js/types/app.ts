import type { PageProps as InertiaPageProps } from '@inertiajs/core'

export type SharedAuthUser = {
  id: string
  email: string
  role: string
  confirmedAt: string | null
  firstName?: string
  lastName?: string
  profileImageUrl?: string | null
}

export type SharedAppProps = {
  app: {
    csrf_token: string
    current_scope: string
    locale: string
    available_locales: string[]
    path: string
    method: string
    unread_count: number
  }
  auth: {
    authenticated: boolean
    user: SharedAuthUser | null
    permissions: Record<string, boolean>
  }
  flash: Partial<Record<'info' | 'success' | 'error' | 'warning', string>>
  i18n: {
    locale: string
    default_locale: string
    translations: Record<string, Record<string, string | Record<string, string>>>
  }
}

export type AppPageProps<TProps = Record<string, unknown>> = InertiaPageProps<
  SharedAppProps & TProps
>
