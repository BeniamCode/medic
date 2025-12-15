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
import { FormEvent } from 'react'
import { useIsMobile } from '@/lib/device'

// Mobile imports
import { Button as MobileButton, Input as MobileInput, Form as MobileForm, Card as MobileCard } from 'antd-mobile'

const { Title, Text } = Typography

// =============================================================================
// MOBILE REGISTER DOCTOR
// =============================================================================

function MobileRegisterDoctorPage() {
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
                <h1 style={{ fontSize: 28, fontWeight: 700, margin: '0 0 8px' }}>Join as a Specialist</h1>
                <p style={{ color: '#666', margin: 0, fontSize: 15 }}>Managing your practice has never been easier</p>
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
                            Start Application
                        </MobileButton>
                    }
                >
                    <div style={{ display: 'flex', gap: 12 }}>
                        <MobileForm.Item
                            label="First name"
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
                            label="Last name"
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
                        label="Email address"
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
                        label="Password"
                        name="password"
                        help={errors.password}
                    >
                        <MobileInput
                            type="password"
                            placeholder="Min. 8 characters"
                            value={data.password}
                            onChange={(val) => setData('password', val)}
                            clearable
                        />
                    </MobileForm.Item>
                </MobileForm>
            </MobileCard>

            <p style={{ textAlign: 'center', marginTop: 20, fontSize: 14 }}>
                Are you a patient?{' '}
                <a onClick={() => router.visit('/register')} style={{ fontWeight: 600, color: '#0d9488' }}>
                    Create Patient Account
                </a>
            </p>

            <p style={{ textAlign: 'center', marginTop: 8, fontSize: 14 }}>
                Already have an account?{' '}
                <a onClick={() => router.visit('/login')} style={{ fontWeight: 600, color: '#0d9488' }}>
                    Sign in
                </a>
            </p>
        </div>
    )
}

// =============================================================================
// DESKTOP REGISTER DOCTOR (Original)
// =============================================================================

function DesktopRegisterDoctorPage() {
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
                <Title level={1}>Join as a Specialist</Title>
                <Text type="secondary">Managing your practice has never been easier</Text>
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
                                    <div style={{ marginBottom: 8 }}><Text strong>First name</Text></div>
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
                                    <div style={{ marginBottom: 8 }}><Text strong>Last name</Text></div>
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
                            <div style={{ marginBottom: 8 }}><Text strong>Email address</Text></div>
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
                            <div style={{ marginBottom: 8 }}><Text strong>Password</Text></div>
                            <DesktopInput.Password
                                placeholder="Min. 8 characters"
                                value={data.password}
                                onChange={(e) => setData('password', e.target.value)}
                            />
                        </Form.Item>

                        <DesktopButton type="primary" htmlType="submit" loading={processing} block size="large" style={{ marginTop: 24 }}>
                            Start Application
                        </DesktopButton>
                    </Flex>
                </form>
            </DesktopCard>

            <Text style={{ display: 'block', textAlign: 'center', marginTop: 16 }}>
                Are you a patient?{' '}
                <Link href="/register" style={{ fontWeight: 700 }}>
                    Create Patient Account
                </Link>
            </Text>

            <Text style={{ display: 'block', textAlign: 'center', marginTop: 8 }}>
                Already have an account?{' '}
                <Link href="/login" style={{ fontWeight: 700 }}>
                    Sign in
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
