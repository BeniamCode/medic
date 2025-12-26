import type { AppPageProps } from '@/types/app'
import { useIsMobile } from '@/lib/device'
import { Spin } from 'antd'
import { lazy, Suspense } from 'react'

const HomeMobile = lazy(() => import('./HomeMobile'))
const HomeDesktop = lazy(() => import('./HomeDesktop'))

export default function HomePage(props: AppPageProps) {
  const isMobile = useIsMobile()

  return (
    <Suspense fallback={<div style={{ height: '100vh', display: 'flex', justifyContent: 'center', alignItems: 'center' }}><Spin size="large" /></div>}>
      {isMobile ? <HomeMobile /> : <HomeDesktop />}
    </Suspense>
  )
}
