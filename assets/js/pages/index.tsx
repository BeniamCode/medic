import type { ComponentType } from 'react'
import AppLayout from '../layouts/AppShell'

export type PageComponent<P = Record<string, unknown>> = ComponentType<P> & {
  layout?: (page: React.ReactNode) => React.ReactNode
}

type Loader = () => Promise<{ default: PageComponent<any> }>

const pageRegistry: Record<string, Loader> = {
  'Public/Home': () => import('./public/Home'),
  'Public/Search': () => import('./public/Search'),
  'Public/DoctorProfile': () => import('./public/DoctorProfile'),
  'Auth/Login': () => import('./auth/Login'),
  'Auth/Register': () => import('./auth/Register'),
  'Auth/RegisterDoctor': () => import('./auth/RegisterDoctor')
}

const privatePages: Record<string, Loader> = {
  'Patient/Dashboard': () => import('./patient/Dashboard'),
  'Patient/AppointmentDetail': () => import('./patient/AppointmentDetail'),
  'Patient/Settings': () => import('./patient/Settings'),
  'Doctor/Dashboard': () => import('./doctor/Dashboard'),
  'Doctor/Profile': () => import('./doctor/Profile'),
  'Doctor/Schedule': () => import('./doctor/Schedule'),
  'Doctor/Onboarding': () => import('./doctor/Onboarding')
}

const notificationsPages: Record<string, Loader> = {
  'Notifications/Index': () => import('./notifications/Index')
}

export const resolvePage = async (name: string) => {
  const loader = pageRegistry[name] || privatePages[name] || notificationsPages[name]

  if (!loader) {
    throw new Error(`Unknown Inertia page: ${name}`)
  }

  const page = await loader()
  page.default.layout ??= (pageNode: React.ReactNode) => <AppLayout>{pageNode} </AppLayout>

  return page
}
