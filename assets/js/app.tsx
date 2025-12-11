import '@mantine/core/styles.css'
import '@mantine/dates/styles.css'
import '@mantine/notifications/styles.css'
import '../css/app.css'

import { MantineProvider, createTheme } from '@mantine/core'
import { InertiaProgress } from '@inertiajs/progress'
import { createInertiaApp, router } from '@inertiajs/react'
import { Notifications } from '@mantine/notifications'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'

import { ensureI18n } from '@/lib/i18n'
import type { AppPageProps, SharedAppProps } from '@/types/app'
import { resolvePage } from '@/pages'
import axios from 'axios'

const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content')

if (csrfToken) {
  // Ensure traditional axios requests include the CSRF token
  axios.defaults.headers.common['X-CSRF-TOKEN'] = csrfToken

  // Inertia uses fetch under the hood, so we manually push the CSRF header
  document.addEventListener('inertia:before', (event) => {
    event.detail.visit.headers = {
      ...event.detail.visit.headers,
      'x-csrf-token': csrfToken
    }
  })
}


const theme = createTheme({
  primaryColor: 'teal',
  colors: {
    teal: [
      '#F0FDFA',
      '#CCFBF1',
      '#99F6E4',
      '#5EEAD4',
      '#2DD4BF',
      '#14B8A6',
      '#0D9488',
      '#0F766E',
      '#115E59',
      '#134E4A'
    ]
  },
  defaultRadius: 'md',
  fontFamily: 'Inter, system-ui, sans-serif',
  headings: {
    fontFamily: 'Inter, system-ui, sans-serif',
    fontWeight: '700'
  },
  components: {
    Button: {
      defaultProps: {
        radius: 'md',
        fw: 600
      }
    },
    Input: {
      defaultProps: {
        radius: 'md'
      }
    },
    Card: {
      defaultProps: {
        radius: 'lg',
        shadow: 'sm',
        withBorder: true
      }
    }
  }
})

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
