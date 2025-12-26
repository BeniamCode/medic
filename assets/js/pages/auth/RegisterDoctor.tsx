import {
    Button as DesktopButton,
    Card as DesktopCard,
    Input as DesktopInput,
    Typography,
    Form,
    Flex,
    Row,
    Col
} from 'antd'
import { Link, useForm, router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import { FormEvent } from 'react'
import { useIsMobile } from '@/lib/device'

// Mobile imports
import { Button as MobileButton, Input as MobileInput, Form as MobileForm, Card as MobileCard } from 'antd-mobile'

const { Title, Text } = Typography

// =============================================================================
// MOBILE REGISTER DOCTOR
// =============================================================================

function MobileRegisterDoctorPage() {
    const { t } = useTranslation('default')
    const { data, setData, post, processing, errors } = useForm({
        email: '',
        password: '',
        first_name: '',
        last_name: ''
    })

    const submit = () => {
        post('/register/doctor')
    }

    return (
        <div style={{ padding: 20, minHeight: '80vh', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
            <div style={{ textAlign: 'center', marginBottom: 32 }}>
                <h1 style={{ fontSize: 28, fontWeight: 700, margin: '0 0 8px' }}>{t('Join as a Specialist')}</h1>
                <p style={{ color: '#666', margin: 0, fontSize: 15 }}>{t('Managing your practice has never been easier')}</p>
            </div>

            <MobileCard style={{ borderRadius: 16 }}>
                <MobileForm
                    layout="vertical"
                    onFinish={submit}
                    footer={
                        <MobileButton
                            block
                            type="submit"
                            color="primary"
                            size="large"
                            loading={processing}
                            style={{ '--border-radius': '8px' }}
                        >
                            {t('Start Application')}
                        </MobileButton>
                    }
                >
                    <div style={{ display: 'flex', gap: 12 }}>
                        <MobileForm.Item
                            label={t('First name')}
                            name="first_name"
                            style={{ flex: 1 }}
                            help={errors.first_name}
                        >
                            <MobileInput
                                placeholder="John"
                                value={data.first_name}
                                onChange={(val) => setData('first_name', val)}
                                clearable
                            />
                        </MobileForm.Item>

                        <MobileForm.Item
                            label={t('Last name')}
                            name="last_name"
                            style={{ flex: 1 }}
                            help={errors.last_name}
                        >
                            <MobileInput
                                placeholder="Doe"
                                value={data.last_name}
                                onChange={(val) => setData('last_name', val)}
                                clearable
                            />
                        </MobileForm.Item>
                    </div>

                    <MobileForm.Item
                        label={t('Email address')}
                        name="email"
                        help={errors.email}
                    >
                        <MobileInput
                            placeholder="doctor@clinic.com"
                            value={data.email}
                            onChange={(val) => setData('email', val)}
                            clearable
                        />
                    </MobileForm.Item>

                    <MobileForm.Item
                        label={t('Password')}
                        name="password"
                        help={errors.password}
                    >
                        <MobileInput
                            type="password"
                            placeholder={t('Min. 8 characters')}
                            value={data.password}
                            onChange={(val) => setData('password', val)}
                            clearable
                        />
                    </MobileForm.Item>
                </MobileForm>
            </MobileCard>

            <p style={{ textAlign: 'center', marginTop: 20, fontSize: 14 }}>
                {t('Are you a patient?')}{' '}
                <a onClick={() => router.visit('/register')} style={{ fontWeight: 600, color: '#0d9488' }}>
                    {t('Create Patient Account')}
                </a>
            </p>

            <p style={{ textAlign: 'center', marginTop: 8, fontSize: 14 }}>
                {t('Already have an account?')}{' '}
                <a onClick={() => router.visit('/login')} style={{ fontWeight: 600, color: '#0d9488' }}>
                    {t('Sign in')}
                </a>
            </p>
        </div>
    )
}

// =============================================================================
// DESKTOP REGISTER DOCTOR (Original)
// =============================================================================

function DesktopRegisterDoctorPage() {
    const { t } = useTranslation('default')
    const { data, setData, post, processing, errors } = useForm({
        email: '',
        password: '',
        first_name: '',
        last_name: ''
    })

    const submit = (e: FormEvent) => {
        e.preventDefault()
        post('/register/doctor')
    }

    return (
        <div style={{ maxWidth: 400, margin: '80px auto' }}>
            <Flex vertical align="center" style={{ marginBottom: 32 }}>
                <Title level={1}>{t('Join as a Specialist')}</Title>
                <Text type="secondary">{t('Managing your practice has never been easier')}</Text>
            </Flex>

            <DesktopCard bordered style={{ padding: 24 }}>
                <form onSubmit={submit}>
                    <Flex vertical gap="middle">
                        <Row gutter={16}>
                            <Col span={12}>
                                <Form.Item
                                    validateStatus={errors.first_name ? 'error' : ''}
                                    help={errors.first_name}
                                    style={{ marginBottom: 0 }}
                                >
                                    <div style={{ marginBottom: 8 }}><Text strong>{t('First name')}</Text></div>
                                    <DesktopInput
                                        placeholder="John"
                                        value={data.first_name}
                                        onChange={(e) => setData('first_name', e.target.value)}
                                    />
                                </Form.Item>
                            </Col>
                            <Col span={12}>
                                <Form.Item
                                    validateStatus={errors.last_name ? 'error' : ''}
                                    help={errors.last_name}
                                    style={{ marginBottom: 0 }}
                                >
                                    <div style={{ marginBottom: 8 }}><Text strong>{t('Last name')}</Text></div>
                                    <DesktopInput
                                        placeholder="Doe"
                                        value={data.last_name}
                                        onChange={(e) => setData('last_name', e.target.value)}
                                    />
                                </Form.Item>
                            </Col>
                        </Row>

                        <Form.Item
                            validateStatus={errors.email ? 'error' : ''}
                            help={errors.email}
                            style={{ marginBottom: 0 }}
                        >
                            <div style={{ marginBottom: 8 }}><Text strong>{t('Email address')}</Text></div>
                            <DesktopInput
                                placeholder="doctor@clinic.com"
                                value={data.email}
                                onChange={(e) => setData('email', e.target.value)}
                            />
                        </Form.Item>

                        <Form.Item
                            validateStatus={errors.password ? 'error' : ''}
                            help={errors.password}
                            style={{ marginBottom: 0 }}
                        >
                            <div style={{ marginBottom: 8 }}><Text strong>{t('Password')}</Text></div>
                            <DesktopInput.Password
                                placeholder={t('Min. 8 characters')}
                                value={data.password}
                                onChange={(e) => setData('password', e.target.value)}
                            />
                        </Form.Item>

                        <DesktopButton type="primary" htmlType="submit" loading={processing} block size="large" style={{ marginTop: 24 }}>
                            {t('Start Application')}
                        </DesktopButton>
                    </Flex>
                </form>
            </DesktopCard>

            <Text style={{ display: 'block', textAlign: 'center', marginTop: 16 }}>
                {t('Are you a patient?')}{' '}
                <Link href="/register" style={{ fontWeight: 700 }}>
                    {t('Create Patient Account')}
                </Link>
            </Text>

            <Text style={{ display: 'block', textAlign: 'center', marginTop: 8 }}>
                {t('Already have an account?')}{' '}
                <Link href="/login" style={{ fontWeight: 700 }}>
                    {t('Sign in')}
                </Link>
            </Text>
        </div>
    )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export default function RegisterDoctorPage() {
    const isMobile = useIsMobile()

    if (isMobile) {
        return <MobileRegisterDoctorPage />
    }

    return <DesktopRegisterDoctorPage />
}
