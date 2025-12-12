import '@mantine/core/styles.css'
import '@mantine/dates/styles.css'
import '@mantine/notifications/styles.css'
import '../css/app.css'

import { MantineProvider, ColorSchemeScript, createTheme } from '@mantine/core'
import { InertiaProgress } from '@inertiajs/progress'
import { createInertiaApp, router } from '@inertiajs/react'
import { Notifications } from '@mantine/notifications'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode, createContext, useContext, useState } from 'react'
import { createRoot } from 'react-dom/client'
import { useLocalStorage } from '@mantine/hooks'

import { ensureI18n } from '@/lib/i18n'
import type { AppPageProps, SharedAppProps } from '@/types/app'
import { resolvePage } from '@/pages'
import axios from 'axios'

// Mutable store for CSRF token
let currentCsrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''

if (currentCsrfToken) {
  // Ensure traditional axios requests include the CSRF token
  axios.defaults.headers.common['X-CSRF-TOKEN'] = currentCsrfToken

  // Inertia uses fetch under the hood, so we manually push the CSRF header
  document.addEventListener('inertia:before', (event) => {
    event.detail.visit.headers = {
      ...event.detail.visit.headers,
      'x-csrf-token': currentCsrfToken
    }
  })
}

// Update CSRF token on each navigation (if provided in props)
router.on('success', (event) => {
  const newProps = event.detail.page.props as SharedAppProps
  const newToken = newProps.app?.csrfToken

  if (newToken && newToken !== currentCsrfToken) {
    currentCsrfToken = newToken
    axios.defaults.headers.common['X-CSRF-TOKEN'] = newToken
    // Update meta tag for consistency
    document.querySelector("meta[name='csrf-token']")?.setAttribute('content', newToken)
  }

  void ensureI18n(newProps.i18n)
})


const surfaceBorder = 'rgba(15, 23, 42, 0.08)'

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
      },
      styles: {
        root: {
          borderRadius: '12px',
          boxShadow: 'none'
        }
      }
    },
    Input: {
      defaultProps: {
        radius: 'md'
      },
      styles: {
        input: {
          borderColor: surfaceBorder,
          boxShadow: 'none'
        }
      }
    },
    Textarea: {
      styles: {
        input: {
          borderColor: surfaceBorder,
          boxShadow: 'none'
        }
      }
    },
    Card: {
      defaultProps: {
        radius: 'md',
        withBorder: true
      },
      styles: {
        root: {
          borderColor: surfaceBorder,
          boxShadow: 'none'
        }
      }
    },
    Paper: {
      styles: {
        root: {
          borderColor: surfaceBorder,
          boxShadow: 'none'
        }
      }
    }
  }
})

type ColorScheme = 'light' | 'dark'

type ThemeModeContextValue = {
  colorScheme: ColorScheme
  toggleColorScheme: () => void
}

const ThemeModeContext = createContext<ThemeModeContextValue | null>(null)

export const useThemeMode = () => {
  const context = useContext(ThemeModeContext)
  if (!context) {
    throw new Error('useThemeMode must be used within ThemeModeProvider')
  }
  return context
}

function ThemeModeProvider({ children }: { children: React.ReactNode }) {
  const [colorScheme, setColorScheme] = useLocalStorage<ColorScheme>({
    key: 'medic-color-scheme',
    defaultValue: 'light'
  })

  const toggleColorScheme = () =>
    setColorScheme((current) => (current === 'dark' ? 'light' : 'dark'))

  return (
    <ThemeModeContext.Provider value={{ colorScheme, toggleColorScheme }}>
      <ColorSchemeScript defaultColorScheme="light" />
      <MantineProvider
        theme={theme}
        defaultColorScheme="light"
        forceColorScheme={colorScheme}
      >
        <Notifications position="top-right" limit={4} />
        {children}
      </MantineProvider>
    </ThemeModeContext.Provider>
  )
}

const queryClient = new QueryClient()

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
        <QueryClientProvider client={queryClient}>
          <ThemeModeProvider>
            <App {...props} />
          </ThemeModeProvider>
        </QueryClientProvider>
      </StrictMode>
    )
  }
})

router.on('success', (event) => {
  void ensureI18n((event.detail.page.props as SharedAppProps).i18n)
})

InertiaProgress.init({ color: '#1f7aec', showSpinner: false })
