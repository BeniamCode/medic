import {
  Button as DesktopButton,
  Card as DesktopCard,
  Col,
  Row,
  Typography,
  Tag,
  Avatar,
  Space
} from 'antd'
import { IconCalendar, IconDeviceLaptop, IconSearch, IconStethoscope, IconUserCheck } from '@tabler/icons-react'
import { Link, router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'
import { LoopAnimation } from '@/components/LoopAnimation'
import { useIsMobile } from '@/lib/device'

// Mobile imports
import { Button as MobileButton, Card as MobileCard, Tag as MobileTag, Grid } from 'antd-mobile'
import { SearchOutline, UserAddOutline } from 'antd-mobile-icons'

const { Title, Text } = Typography

const features = [
  {
    icon: IconSearch,
    title: 'Easy Search',
    description: 'Find specialists by name, specialty, or location instantly.'
  },
  {
    icon: IconCalendar,
    title: 'Instant Booking',
    description: 'Real-time availability means no more phone tag.'
  },
  {
    icon: IconUserCheck,
    title: 'Verified Doctors',
    description: 'Every specialist is vetted for license and quality.'
  },
  {
    icon: IconDeviceLaptop,
    title: 'Telemedicine',
    description: 'Connect with doctors from the comfort of your home.'
  }
]

// =============================================================================
// MOBILE HOME PAGE
// =============================================================================

function MobileHomePage() {
  return (
    <div style={{ padding: 16, paddingBottom: 80 }}>
      {/* Hero Section */}
      <div style={{ textAlign: 'center', padding: '24px 0 32px' }}>
        <MobileTag color="primary" fill="outline" style={{ marginBottom: 16 }}>
          New: Telemedicine Support
        </MobileTag>

        <h1 style={{ fontSize: 28, fontWeight: 700, lineHeight: 1.2, margin: '0 0 12px' }}>
          Modern healthcare for <span style={{ color: '#0d9488' }}>everyone</span>
        </h1>

        <p style={{ fontSize: 15, color: '#666', margin: '0 0 24px', lineHeight: 1.5 }}>
          Book appointments with trusted doctors, manage your visits, and take control of your health journey.
        </p>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <MobileButton
            block
            color="primary"
            size="large"
            onClick={() => router.visit('/search')}
            style={{ '--border-radius': '24px', height: 48 }}
          >
            <SearchOutline style={{ marginRight: 8 }} />
            Find a Doctor
          </MobileButton>

          <MobileButton
            block
            size="large"
            onClick={() => router.visit('/register')}
            style={{ '--border-radius': '24px', height: 48 }}
          >
            <UserAddOutline style={{ marginRight: 8 }} />
            Join as Patient
          </MobileButton>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12, marginTop: 24 }}>
          <Avatar.Group maxCount={3} size="small">
            {[...Array(3)].map((_, i) => (
              <Avatar key={i} style={{ backgroundColor: `rgba(0,0,0,${0.1 * (i + 1)})` }} />
            ))}
          </Avatar.Group>
          <span style={{ fontSize: 13, color: '#666' }}>
            Trusted by 10,000+ patients
          </span>
        </div>
      </div>

      {/* Features Grid */}
      <div style={{ marginTop: 16 }}>
        <Grid columns={2} gap={12}>
          {features.map((feature) => (
            <Grid.Item key={feature.title}>
              <MobileCard style={{ borderRadius: 12, height: '100%' }}>
                <div
                  style={{
                    width: 40,
                    height: 40,
                    borderRadius: 8,
                    backgroundColor: '#e6fffa',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    marginBottom: 12,
                    color: '#0d9488'
                  }}
                >
                  <feature.icon size={20} stroke={1.5} />
                </div>
                <div style={{ fontWeight: 600, fontSize: 14, marginBottom: 4 }}>{feature.title}</div>
                <div style={{ fontSize: 12, color: '#666', lineHeight: 1.4 }}>{feature.description}</div>
              </MobileCard>
            </Grid.Item>
          ))}
        </Grid>
      </div>

      {/* CTA Section */}
      <MobileCard
        style={{
          marginTop: 24,
          borderRadius: 16,
          backgroundColor: '#134e4a',
          color: 'white'
        }}
      >
        <div style={{ textAlign: 'center', padding: '8px 0' }}>
          <div
            style={{
              width: 48,
              height: 48,
              borderRadius: 12,
              backgroundColor: 'white',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#0d9488',
              margin: '0 auto 16px'
            }}
          >
            <IconStethoscope size={24} />
          </div>
          <h3 style={{ color: 'white', fontSize: 18, fontWeight: 600, margin: '0 0 8px' }}>
            Are you a doctor?
          </h3>
          <p style={{ color: '#ccfbf1', fontSize: 13, margin: '0 0 16px', lineHeight: 1.4 }}>
            Join our network of verified specialists and grow your practice.
          </p>
          <MobileButton
            size="large"
            onClick={() => router.visit('/register/doctor')}
            style={{
              '--background-color': 'white',
              '--text-color': '#0d9488',
              '--border-radius': '24px',
              fontWeight: 600
            }}
          >
            Join Medic Network
          </MobileButton>
        </div>
      </MobileCard>
    </div>
  )
}

// =============================================================================
// DESKTOP HOME PAGE (Original)
// =============================================================================

function DesktopHomePage() {
  return (
    <div style={{ paddingBottom: 80, display: 'flex', flexDirection: 'column', gap: 80 }}>
      {/* Hero Section */}
      <div style={{ maxWidth: 1200, margin: '0 auto', padding: '0 24px', width: '100%' }}>
        <Row gutter={50} align="middle">
          <Col xs={24} md={12}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
              <div>
                <Tag color="cyan" style={{ borderRadius: 999, fontSize: 14, padding: '4px 12px' }}>
                  New: Telemedicine Support
                </Tag>
              </div>

              <Title level={1} style={{ fontSize: 52, lineHeight: 1.1, margin: 0 }}>
                Modern healthcare for <Text style={{ fontSize: 52, lineHeight: 1.1, color: '#0d9488' }} strong>everyone</Text>
              </Title>

              <Text type="secondary" style={{ fontSize: 20 }}>
                Book appointments with trusted doctors, manage your visits, and take control of your health journey—all in one place.
              </Text>

              <Space size="middle">
                <Link href="/search">
                  <DesktopButton
                    type="primary"
                    size="large"
                    shape="round"
                    icon={<IconSearch size={20} />}
                    style={{ height: 50, paddingLeft: 32, paddingRight: 32 }}
                  >
                    Find a Doctor
                  </DesktopButton>
                </Link>
                <Link href="/register">
                  <DesktopButton
                    size="large"
                    shape="round"
                    style={{ height: 50, paddingLeft: 32, paddingRight: 32 }}
                  >
                    Join as Patient
                  </DesktopButton>
                </Link>
              </Space>

              <Space align="center" size="large" style={{ marginTop: 24 }}>
                <Avatar.Group maxCount={4}>
                  {[...Array(4)].map((_, i) => (
                    <Avatar key={i} style={{ backgroundColor: `rgba(0,0,0,${0.1 * (i + 1)})` }} />
                  ))}
                  <Avatar style={{ backgroundColor: '#f56a00' }}>10k+</Avatar>
                </Avatar.Group>
                <Text type="secondary" style={{ fontSize: 14 }}>
                  Trusted by 10,000+ patients
                </Text>
              </Space>
            </div>
          </Col>

          <Col xs={24} md={12} className="hidden md:block">
            <div style={{ width: '100%', height: 400 }}>
              <LoopAnimation />
            </div>
          </Col>
        </Row>
      </div>

      {/* Features Grid */}
      <div style={{ maxWidth: 1200, margin: '0 auto', padding: '0 24px', width: '100%' }}>
        <Row gutter={[24, 24]}>
          {features.map((feature) => (
            <Col xs={24} sm={12} md={6} key={feature.title}>
              <DesktopCard
                hoverable
                style={{ height: '100%', borderRadius: 16 }}
                styles={{ body: { padding: 24 } }}
              >
                <div style={{
                  width: 48,
                  height: 48,
                  borderRadius: 8,
                  backgroundColor: '#e6fffa',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  marginBottom: 24,
                  color: '#0d9488'
                }}>
                  <feature.icon size={24} stroke={1.5} />
                </div>
                <Text strong style={{ fontSize: 18, display: 'block', marginBottom: 8 }}>{feature.title}</Text>
                <Text type="secondary" style={{ lineHeight: 1.6 }}>{feature.description}</Text>
              </DesktopCard>
            </Col>
          ))}
        </Row>
      </div>

      {/* CTA Section */}
      <div style={{ maxWidth: 960, margin: '0 auto', padding: '0 24px', width: '100%' }}>
        <DesktopCard
          style={{
            borderRadius: 24,
            backgroundColor: '#134e4a',
            color: 'white',
            textAlign: 'center'
          }}
          styles={{ body: { padding: 60 } }}
          bordered={false}
        >
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 24 }}>
            <div style={{
              width: 60,
              height: 60,
              borderRadius: 20,
              backgroundColor: 'white',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              color: '#0d9488'
            }}>
              <IconStethoscope size={30} />
            </div>
            <Title level={2} style={{ color: 'white', margin: 0 }}>Are you a qualified doctor?</Title>
            <Text style={{ color: '#ccfbf1', maxWidth: 500 }}>
              Join our network of over 600 verified specialists. specific tools to manage your schedule and grow your practice.
            </Text>
            <Link href="/register/doctor">
              <DesktopButton
                size="large"
                shape="round"
                style={{
                  height: 50,
                  color: '#0d9488',
                  borderColor: 'white',
                  backgroundColor: 'white',
                  fontWeight: 600
                }}
              >
                Join Medic Network
              </DesktopButton>
            </Link>
          </div>
        </DesktopCard>
      </div>
    </div>
  )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export default function HomePage({ app, auth }: AppPageProps) {
  const isMobile = useIsMobile()
  const { t } = useTranslation('default')

  if (isMobile) {
    return <MobileHomePage />
  }

  return <DesktopHomePage />
}
