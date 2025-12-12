import '../css/app.css'

import { ConfigProvider, App as AntApp, theme as antTheme } from 'antd'
import { InertiaProgress } from '@inertiajs/progress'
import { createInertiaApp, router } from '@inertiajs/react'
import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode, createContext, useContext, useState } from 'react'
import { createRoot } from 'react-dom/client'

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

