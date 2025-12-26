import { Button, Card, Tag, Grid } from 'antd-mobile'
import { SearchOutline, UserAddOutline } from 'antd-mobile-icons'
import { Avatar } from 'antd'
import { IconCalendar, IconDeviceLaptop, IconSearch, IconStethoscope, IconUserCheck } from '@tabler/icons-react'
import { router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'

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

export default function HomeMobile() {
    const { t } = useTranslation('default')

    return (
        <div style={{ padding: 16, paddingBottom: 80 }}>
            {/* Hero Section */}
            <div style={{ textAlign: 'center', padding: '24px 0 32px' }}>
                <Tag color="primary" fill="outline" style={{ marginBottom: 16 }}>
                    {t('New: Telemedicine Support')}
                </Tag>

                <h1 style={{ fontSize: 28, fontWeight: 700, lineHeight: 1.2, margin: '0 0 12px' }}>
                    {t('Modern healthcare for')} <span style={{ color: '#0d9488' }}>{t('everyone')}</span>
                </h1>

                <p style={{ fontSize: 15, color: '#666', margin: '0 0 24px', lineHeight: 1.5 }}>
                    {t('Book appointments with trusted doctors, manage your visits, and take control of your health journey.')}
                </p>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    <Button
                        block
                        color="primary"
                        size="large"
                        onClick={() => router.visit('/search')}
                        style={{ '--border-radius': '24px', height: 48 }}
                    >
                        <SearchOutline style={{ marginRight: 8 }} />
                        {t('Find a Doctor')}
                    </Button>

                    <Button
                        block
                        size="large"
                        onClick={() => router.visit('/register')}
                        style={{ '--border-radius': '24px', height: 48 }}
                    >
                        <UserAddOutline style={{ marginRight: 8 }} />
                        {t('Join as Patient')}
                    </Button>
                </div>

                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 12, marginTop: 24 }}>
                    <Avatar.Group maxCount={3} size="small">
                        {[...Array(3)].map((_, i) => (
                            <Avatar key={i} style={{ backgroundColor: `rgba(0,0,0,${0.1 * (i + 1)})` }} />
                        ))}
                    </Avatar.Group>
                    <span style={{ fontSize: 13, color: '#666' }}>
                        {t('Trusted by 10,000+ patients')}
                    </span>
                </div>
            </div>

            {/* Features Grid */}
            <div style={{ marginTop: 16 }}>
                <Grid columns={2} gap={12}>
                    {features.map((feature) => (
                        <Grid.Item key={feature.title}>
                            <Card style={{ borderRadius: 12, height: '100%' }}>
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
                                <div style={{ fontWeight: 600, fontSize: 14, marginBottom: 4 }}>{t(feature.title)}</div>
                                <div style={{ fontSize: 12, color: '#666', lineHeight: 1.4 }}>{t(feature.description)}</div>
                            </Card>
                        </Grid.Item>
                    ))}
                </Grid>
            </div>

            {/* CTA Section */}
            <Card
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
                        {t('Are you a doctor?')}
                    </h3>
                    <p style={{ color: '#ccfbf1', fontSize: 13, margin: '0 0 16px', lineHeight: 1.4 }}>
                        {t('Join our network of verified specialists and grow your practice.')}
                    </p>
                    <Button
                        size="large"
                        onClick={() => router.visit('/register/doctor')}
                        style={{
                            '--background-color': 'white',
                            '--text-color': '#0d9488',
                            '--border-radius': '24px',
                            fontWeight: 600
                        }}
                    >
                        {t('Join Medic Network')}
                    </Button>
                </div>
            </Card>
        </div>
    )
}
