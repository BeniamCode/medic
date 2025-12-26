import { Button, Card, Col, Row, Typography, Tag, Avatar, Space, Spin } from 'antd'
import { IconCalendar, IconDeviceLaptop, IconSearch, IconStethoscope, IconUserCheck } from '@tabler/icons-react'
import { Link } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import { lazy, Suspense, useState, useEffect } from 'react'

// Lazy load heavy Three.js component with artificial delay to prioritize LCP
const LoopAnimation = lazy(() => import('@/components/LoopAnimation').then(m => ({ default: m.LoopAnimation })))

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

export default function HomeDesktop() {
    const { t } = useTranslation('default')
    const [mountAnimation, setMountAnimation] = useState(false)

    // Delay matching critical requests to avoid blocking LCP
    useEffect(() => {
        const timer = setTimeout(() => setMountAnimation(true), 1500)
        return () => clearTimeout(timer)
    }, [])

    return (
        <main style={{ paddingBottom: 80, display: 'flex', flexDirection: 'column', gap: 80 }} role="main">
            {/* Hero Section */}
            <div style={{ maxWidth: 1200, margin: '0 auto', padding: '0 24px', width: '100%' }}>
                <Row gutter={50} align="middle">
                    <Col xs={24} md={12}>
                        <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
                            <div>
                                <Tag color="cyan" style={{ borderRadius: 999, fontSize: 14, padding: '4px 12px' }}>
                                    {t('New: Telemedicine Support')}
                                </Tag>
                            </div>

                            <Title level={1} style={{ fontSize: 52, lineHeight: 1.1, margin: 0 }}>
                                {t('Modern healthcare for')} <Text style={{ fontSize: 52, lineHeight: 1.1, color: '#0d9488' }} strong>{t('everyone')}</Text>
                            </Title>

                            <Text type="secondary" style={{ fontSize: 20 }}>
                                {t('Book appointments with trusted doctors, manage your visits, and take control of your health journey—all in one place.')}
                            </Text>

                            <Space size="middle">
                                <Link href="/search" prefetch="hover" aria-label="Search for doctors">
                                    <Button
                                        type="primary"
                                        size="large"
                                        shape="round"
                                        icon={<IconSearch size={20} aria-hidden="true" />}
                                        style={{ height: 50, paddingLeft: 32, paddingRight: 32 }}
                                        aria-label="Find a Doctor"
                                    >
                                        {t('Find a Doctor')}
                                    </Button>
                                </Link>
                                <Link href="/register" prefetch="hover">
                                    <Button
                                        size="large"
                                        shape="round"
                                        style={{ height: 50, paddingLeft: 32, paddingRight: 32 }}
                                    >
                                        {t('Join as Patient')}
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
                                    {t('Trusted by 10,000+ patients')}
                                </Text>
                            </Space>
                        </div>
                    </Col>

                    <Col xs={24} md={12} className="hidden md:block">
                        <div style={{ width: '100%', height: 400 }}>
                            {mountAnimation && (
                                <Suspense fallback={<div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', height: '100%' }}><Spin size="large" /></div>}>
                                    <LoopAnimation />
                                </Suspense>
                            )}
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
                                <Text strong style={{ fontSize: 18, display: 'block', marginBottom: 8 }}>{t(feature.title)}</Text>
                                <Text type="secondary" style={{ lineHeight: 1.6 }}>{t(feature.description)}</Text>
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
                        <Title level={2} style={{ color: 'white', margin: 0 }}>{t('Are you a qualified doctor?')}</Title>
                        <Text style={{ color: '#ccfbf1', maxWidth: 500 }}>
                            {t('Join our network of over 600 verified specialists. specific tools to manage your schedule and grow your practice.')}
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
                                {t('Join Medic Network')}
                            </Button>
                        </Link>
                    </div>
                </Card>
            </div>
        </main>
    )
}
