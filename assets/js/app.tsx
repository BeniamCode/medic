import '../css/app.css'

import { ConfigProvider, App as AntApp, theme as antTheme } from 'antd'
import { InertiaProgress } from '@inertiajs/progress'
import { createInertiaApp, router } from '@inertiajs/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode, createContext, useContext, useState } from 'react'
import { hydrateRoot } from 'react-dom/client'

import { ensureI18n } from '@/lib/i18n'
import type { AppPageProps, SharedAppProps } from '@/types/app'
import { resolvePage } from '@/pages'
import axios from 'axios'

// Global CSRF token store - keeps track of the latest token
// This is updated on every Inertia navigation success
let _csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''

// Export helper to get current CSRF token (for use in components)
export const getCSRFToken = () => _csrfToken || document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''

// Make it globally available for components that import differently
if (typeof window !== 'undefined') {
  (window as any).__getCSRFToken = getCSRFToken
}

// Set up Axios defaults for CSRF
axios.defaults.headers.common['X-CSRF-Token'] = getCSRFToken()
axios.defaults.headers.common['X-CSRF-TOKEN'] = getCSRFToken()

// Axios interceptor to always use fresh token
axios.interceptors.request.use((config) => {
  const token = getCSRFToken()
  if (token) {
    config.headers['X-CSRF-Token'] = token
    config.headers['X-CSRF-TOKEN'] = token
  }
  return config
})

// Add CSRF token to ALL Inertia requests
router.on('before', (event) => {
  const token = getCSRFToken()
  if (token && event.detail?.visit) {
    event.detail.visit.headers = {
      ...event.detail.visit.headers,
      'X-CSRF-Token': token,
      'x-csrf-token': token
    }
  }
})

// Update CSRF token on each navigation (if provided in props)
router.on('success', (event) => {
  const newProps = event.detail.page.props as unknown as SharedAppProps
  const newToken = newProps.app?.csrf_token

  if (newToken) {
    // Update our global store
    _csrfToken = newToken
    // Update meta tag for consistency
    document.querySelector("meta[name='csrf-token']")?.setAttribute('content', newToken)
    axios.defaults.headers.common['X-CSRF-TOKEN'] = newToken
    axios.defaults.headers.common['X-CSRF-Token'] = newToken
  }

  void ensureI18n(newProps.i18n)
})

// Simple useLocalStorage hook since we removed @mantine/hooks
function useLocalStorage<T>(key: string, initialValue: T): [T, (value: T | ((val: T) => T)) => void] {
  const [storedValue, setStoredValue] = useState<T>(() => {
    try {
      if (typeof window === 'undefined') {
        return initialValue;
      }
      const item = window.localStorage.getItem(key);
      return item ? JSON.parse(item) : initialValue;
    } catch (error) {
      console.log(error);
      return initialValue;
    }
  });

  const setValue = (value: T | ((val: T) => T)) => {
    try {
      const valueToStore = value instanceof Function ? value(storedValue) : value;
      setStoredValue(valueToStore);
      if (typeof window !== 'undefined') {
        window.localStorage.setItem(key, JSON.stringify(valueToStore));
      }
    } catch (error) {
      console.log(error);
    }
  };

  return [storedValue, setValue];
}

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
  const [colorScheme, setColorScheme] = useLocalStorage<ColorScheme>('medic-color-scheme', 'light')

  const toggleColorScheme = () =>
    setColorScheme((current) => (current === 'dark' ? 'light' : 'dark'))

  return (
    <ThemeModeContext.Provider value={{ colorScheme, toggleColorScheme }}>
      <ConfigProvider
        theme={{
          algorithm: colorScheme === 'dark' ? antTheme.darkAlgorithm : antTheme.defaultAlgorithm,
          token: {
            colorPrimary: '#0D9488', // Teal
            borderRadius: 8,
            fontFamily: 'Inter, system-ui, sans-serif'
          }
        }}
      >
        <AntApp>
          {children}
        </AntApp>
      </ConfigProvider>
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
    axios.defaults.headers.common['X-CSRF-Token'] = (
      props.initialPage.props as SharedAppProps
    ).app.csrf_token
    ensureI18n((props.initialPage.props as SharedAppProps).i18n).then(() => {
      hydrateRoot(
        el,
        <StrictMode>
          <QueryClientProvider client={queryClient}>
            <ThemeModeProvider>
              <App {...props} />
            </ThemeModeProvider>
          </QueryClientProvider>
        </StrictMode>
      )
    })
  }
})



InertiaProgress.init({ color: '#1f7aec', showSpinner: false })

