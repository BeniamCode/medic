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
    csrfToken: string
    currentScope: string
    locale: string
    availableLocales: string[]
    path: string
    method: string
    unreadCount: number
  }
  auth: {
    authenticated: boolean
    user: SharedAuthUser | null
    permissions: Record<string, boolean>
  }
  flash: Partial<Record<'info' | 'success' | 'error' | 'warning', string>>
  i18n: {
    locale: string
    defaultLocale: string
    translations: Record<string, Record<string, string | Record<string, string>>>
  }
}

export type AppPageProps<TProps = Record<string, unknown>> = InertiaPageProps<
  SharedAppProps & TProps
>
