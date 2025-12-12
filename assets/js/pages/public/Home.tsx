import {
  Button,
  Card,
  Col,
  Row,
  Typography,
  Tag,
  Avatar,
  Space
} from 'antd'
import { IconCalendar, IconDeviceLaptop, IconSearch, IconShieldCheck, IconStethoscope, IconUserCheck } from '@tabler/icons-react'
import { Link } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'
import { LoopAnimation } from '@/components/LoopAnimation'

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

export default function HomePage({ app, auth }: AppPageProps) {
  const { t } = useTranslation('default')

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
                Modern healthcare for <Text style={{ color: '#0d9488' }} strong>everyone</Text>
              </Title>

              <Text type="secondary" style={{ fontSize: 20 }}>
                Book appointments with trusted doctors, manage your visits, and take control of your health journey—all in one place.
              </Text>

              <Space size="middle">
                <Link href="/search">
                  <Button
                    type="primary"
                    size="large"
                    shape="round"
                    icon={<IconSearch size={20} />}
                    style={{ height: 50, paddingLeft: 32, paddingRight: 32 }}
                  >
                    Find a Doctor
                  </Button>
                </Link>
                <Link href="/register">
                  <Button
                    size="large"
                    shape="round"
                    style={{ height: 50, paddingLeft: 32, paddingRight: 32 }}
                  >
                    Join as Patient
                  </Button>
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
              <Card
                hoverable
                style={{ height: '100%', borderRadius: 16 }}
                bodyStyle={{ padding: 24 }}
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
              </Card>
            </Col>
          ))}
        </Row>
      </div>

      {/* CTA Section */}
      <div style={{ maxWidth: 960, margin: '0 auto', padding: '0 24px', width: '100%' }}>
        <Card
          style={{
            borderRadius: 24,
            backgroundColor: '#134e4a', // teal-900 equivalent logic or close
            color: 'white',
            textAlign: 'center'
          }}
          bodyStyle={{ padding: 60 }}
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
              <Button
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
              </Button>
            </Link>
          </div>
        </Card>
      </div>
    </div>
  )
}
