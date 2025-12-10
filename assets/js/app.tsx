import '@mantine/core/styles.css'
import '@mantine/dates/styles.css'
import '@mantine/notifications/styles.css'
import '../css/app.css'

import { MantineProvider } from '@mantine/core'
import { InertiaProgress } from '@inertiajs/progress'
import { createInertiaApp, router } from '@inertiajs/react'
import { Notifications } from '@mantine/notifications'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'

import { ensureI18n } from '@/lib/i18n'
import type { AppPageProps, SharedAppProps } from '@/types/app'
import { resolvePage } from '@/pages'

const theme = {
  fontFamily: 'Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif'
}

createInertiaApp<AppPageProps>({
  progress: { showSpinner: false },
  resolve: async (name) => {
    const page = await resolvePage(name)
    const component = page.default

    component.layout ??= (page) => page
    return component
  },
  setup({ el, App, props }) {
    const root = createRoot(el)
    void ensureI18n((props.initialPage.props as SharedAppProps).i18n)

    root.render(
      <StrictMode>
        <MantineProvider theme={theme} defaultColorScheme="light">
          <Notifications position="top-right" limit={4} />
          <App {...props} />
        </MantineProvider>
      </StrictMode>
    )
  }
})

router.on('success', (event) => {
  void ensureI18n((event.detail.page.props as SharedAppProps).i18n)
})

InertiaProgress.init({ color: '#1f7aec', showSpinner: false })
