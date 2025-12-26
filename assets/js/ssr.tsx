import React from 'react'
import ReactDOMServer from 'react-dom/server'
import { createInertiaApp } from '@inertiajs/react'

// Simple page resolver for SSR - must match client resolver
const pageRegistry: Record<string, () => Promise<{ default: React.ComponentType<any> }>> = {
    'Public/Home': () => import('./pages/public/Home'),
    'Public/Search': () => import('./pages/public/Search'),
    'Public/DoctorProfile': () => import('./pages/public/DoctorProfile'),
    'Auth/Login': () => import('./pages/auth/Login'),
    'Auth/Register': () => import('./pages/auth/Register'),
    'Auth/RegisterDoctor': () => import('./pages/auth/RegisterDoctor'),
    'Patient/Dashboard': () => import('./pages/patient/Dashboard'),
    'Patient/AppointmentDetail': () => import('./pages/patient/AppointmentDetail'),
    'Patient/Settings': () => import('./pages/patient/Settings'),
    'Patient/Profile': () => import('./pages/patient/Profile'),
    'Doctor/Dashboard': () => import('./pages/doctor/Dashboard'),
    'Doctor/Appointments': () => import('./pages/doctor/Appointments'),
    'Doctor/Profile': () => import('./pages/doctor/Profile'),
    'Doctor/Schedule': () => import('./pages/doctor/Schedule'),
    'Doctor/Onboarding': () => import('./pages/doctor/Onboarding'),
    'Doctor/BookingCalendar': () => import('./pages/doctor/BookingCalendar'),
    'Notifications/Index': () => import('./pages/notifications/Index'),
    'Admin/Login': () => import('./pages/Admin/Login'),
    'Admin/Dashboard': () => import('./pages/Admin/Dashboard'),
    'Admin/Users': () => import('./pages/Admin/Users'),
    'Admin/Appointments': () => import('./pages/Admin/Appointments'),
    'Admin/Doctors': () => import('./pages/Admin/Doctors'),
    'Admin/Patients': () => import('./pages/Admin/Patients')
}

export function render(page: any) {
    return createInertiaApp({
        page,
        render: ReactDOMServer.renderToString,
        resolve: async (name: string) => {
            const loader = pageRegistry[name]
            if (!loader) {
                throw new Error(`Unknown page for SSR: ${name}`)
            }
            return loader()
        },
        setup: ({ App, props }) => <App {...props} />
    })
}
