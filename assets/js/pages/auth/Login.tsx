import {
    Button as DesktopButton,
    Card as DesktopCard,
    Checkbox,
    Input as DesktopInput,
    Typography,
    Form,
    Flex
} from 'antd'
import { Link, useForm, router } from '@inertiajs/react'
import { FormEvent } from 'react'
import { LockOutlined, MailOutlined } from '@ant-design/icons'
import { useIsMobile } from '@/lib/device'

// Mobile imports
import { Button as MobileButton, Input as MobileInput, Form as MobileForm, Checkbox as MobileCheckbox, Card as MobileCard } from 'antd-mobile'
import { MailOutline, LockOutline } from 'antd-mobile-icons'

const { Title, Text } = Typography

// =============================================================================
// MOBILE LOGIN
// =============================================================================

function MobileLoginPage() {
    const { data, setData, post, processing, errors } = useForm({
        email: '',
        password: '',
        remember_me: false
    })

    const submit = () => {
        post('/login')
    }

    return (
        <div style={{ padding: 20, minHeight: '80vh', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
            <div style={{ textAlign: 'center', marginBottom: 32 }}>
                <h1 style={{ fontSize: 28, fontWeight: 700, margin: '0 0 8px' }}>Welcome back</h1>
                <p style={{ color: '#666', margin: 0, fontSize: 15 }}>Sign in to manage your appointments</p>
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
                            Sign in
                        </MobileButton>
                    }
                >
                    <MobileForm.Item
                        label="Email address"
                        name="email"
                        rules={[{ required: true, message: 'Please enter your email' }]}
                        help={errors.email}
                    >
                        <MobileInput
                            placeholder="you@medic.com"
                            value={data.email}
                            onChange={(val) => setData('email', val)}
                            clearable
                        />
                    </MobileForm.Item>

                    <MobileForm.Item
                        label="Password"
                        name="password"
                        rules={[{ required: true, message: 'Please enter your password' }]}
                        help={errors.password}
                    >
                        <MobileInput
                            type="password"
                            placeholder="Your password"
                            value={data.password}
                            onChange={(val) => setData('password', val)}
                            clearable
                        />
                    </MobileForm.Item>

                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
                        <MobileCheckbox
                            checked={data.remember_me}
                            onChange={(checked) => setData('remember_me', checked)}
                            style={{ '--icon-size': '18px', '--font-size': '14px' }}
                        >
                            Remember me
                        </MobileCheckbox>
                        <a
                            onClick={() => router.visit('/forgot-password')}
                            style={{ fontSize: 14, color: '#0d9488' }}
                        >
                            Forgot password?
                        </a>
                    </div>
                </MobileForm>
            </MobileCard>

            <p style={{ textAlign: 'center', marginTop: 20, fontSize: 14 }}>
                Don't have an account?{' '}
                <a
                    onClick={() => router.visit('/register')}
                    style={{ fontWeight: 600, color: '#0d9488' }}
                >
                    Register
                </a>
            </p>
        </div>
    )
}

// =============================================================================
// DESKTOP LOGIN (Original)
// =============================================================================

function DesktopLoginPage() {
    const { data, setData, post, processing, errors } = useForm({
        email: '',
        password: '',
        remember_me: false
    })

    const submit = (e: FormEvent) => {
        e.preventDefault()
        post('/login')
    }

    return (
        <div style={{ maxWidth: 400, margin: '80px auto' }}>
            <Flex vertical align="center" style={{ marginBottom: 32 }}>
                <Title level={1}>Welcome back</Title>
                <Text type="secondary">Sign in to manage your appointments</Text>
            </Flex>

            <DesktopCard bordered style={{ padding: 24 }}>
                <form onSubmit={submit}>
                    <Flex vertical gap="middle">
                        <Form.Item
                            validateStatus={errors.email ? 'error' : ''}
                            help={errors.email}
                            style={{ marginBottom: 0 }}
                        >
                            <div style={{ marginBottom: 8 }}><Text strong>Email address</Text></div>
                            <DesktopInput
                                prefix={<MailOutlined />}
                                placeholder="you@medic.com"
                                value={data.email}
                                onChange={(e) => setData('email', e.target.value)}
                                size="large"
                            />
                        </Form.Item>

                        <Form.Item
                            validateStatus={errors.password ? 'error' : ''}
                            help={errors.password}
                            style={{ marginBottom: 0 }}
                        >
                            <div style={{ marginBottom: 8 }}><Text strong>Password</Text></div>
                            <DesktopInput.Password
                                prefix={<LockOutlined />}
                                placeholder="Your password"
                                value={data.password}
                                onChange={(e) => setData('password', e.target.value)}
                                size="large"
                            />
                        </Form.Item>

                        <Flex justify="space-between" align="center" style={{ marginTop: 16 }}>
                            <Checkbox
                                checked={data.remember_me}
                                onChange={(e) => setData('remember_me', e.target.checked)}
                            >
                                Remember me
                            </Checkbox>
                            <Link href="/forgot-password" className="text-sm">
                                Forgot password?
                            </Link>
                        </Flex>

                        <DesktopButton type="primary" htmlType="submit" loading={processing} block size="large" style={{ marginTop: 24 }}>
                            Sign in
                        </DesktopButton>
                    </Flex>
                </form>
            </DesktopCard>

            <Text style={{ display: 'block', textAlign: 'center', marginTop: 16 }}>
                Don&apos;t have an account?{' '}
                <Link href="/register" style={{ fontWeight: 700 }}>
                    Register
                </Link>
            </Text>
        </div>
    )
}

// =============================================================================
// MAIN COMPONENT
// =============================================================================

export default function LoginPage() {
    const isMobile = useIsMobile()

    if (isMobile) {
        return <MobileLoginPage />
    }

    return <DesktopLoginPage />
}
