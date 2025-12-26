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
  'Patient/Profile': () => import('./patient/Profile'),
  'Doctor/Dashboard': () => import('./doctor/Dashboard'),
  'Doctor/Appointments': () => import('./doctor/Appointments'),
  'Doctor/Profile': () => import('./doctor/Profile'),
  'Doctor/Schedule': () => import('./doctor/Schedule'),
  'Doctor/Onboarding': () => import('./doctor/Onboarding'),
  'Doctor/BookingCalendar': () => import('./doctor/BookingCalendar')
}

const notificationsPages: Record<string, Loader> = {
  'Notifications/Index': () => import('./notifications/Index')
}

const adminPages: Record<string, Loader> = {
  'Admin/Login': () => import('./Admin/Login'),
  'Admin/Dashboard': () => import('./Admin/Dashboard'),
  'Admin/Users': () => import('./Admin/Users'),
  'Admin/Appointments': () => import('./Admin/Appointments'),
  'Admin/Doctors': () => import('./Admin/Doctors'),
  'Admin/Patients': () => import('./Admin/Patients'),
  'Admin/EmailTemplates/Index': () => import('./Admin/EmailTemplates/Index'),
  'Admin/EmailTemplates/Form': () => import('./Admin/EmailTemplates/Form'),
  'Admin/EmailLogs/Index': () => import('./Admin/EmailLogs/Index')
}

export const resolvePage = async (name: string) => {
  const loader = pageRegistry[name] || privatePages[name] || notificationsPages[name] || adminPages[name]

  if (!loader) {
    throw new Error(`Unknown Inertia page: ${name}`)
  }

  const page = await loader()

  // Don't apply default layout for admin pages (they have their own)
  if (!name.startsWith('Admin/')) {
    page.default.layout ??= (pageNode: React.ReactNode) => <AppLayout>{pageNode}</AppLayout>
  }

  return page
}
