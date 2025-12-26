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
import { Link, router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import { useIsMobile } from '@/lib/device'
import { useForm, Controller } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { useState } from 'react'

// Mobile imports
import { Button as MobileButton, Input as MobileInput, Form as MobileForm, Card as MobileCard } from 'antd-mobile'

const { Title, Text } = Typography

// =============================================================================
// SCHEMA
// =============================================================================

const registerSchema = z.object({
    first_name: z.string().min(2, "First name is required"),
    last_name: z.string().min(2, "Last name is required"),
    email: z.string().email("Invalid email address"),
    password: z.string().min(8, "Password must be at least 8 characters")
})

type RegisterFormData = z.infer<typeof registerSchema>

// =============================================================================
// MOBILE REGISTER
// =============================================================================

function MobileRegisterPage() {
    const { t } = useTranslation('default')
    const [loading, setLoading] = useState(false)

    const { control, handleSubmit, setError, formState: { errors } } = useForm<RegisterFormData>({
        resolver: zodResolver(registerSchema),
        defaultValues: {
            first_name: '',
            last_name: '',
            email: '',
            password: ''
        }
    })

    const onSubmit = (data: RegisterFormData) => {
        if (loading) return
        setLoading(true)

        router.post('/register', data, {
            onError: (serverErrors) => {
                setLoading(false)
                Object.keys(serverErrors).forEach((key) => {
                    setError(key as keyof RegisterFormData, {
                        type: 'server',
                        message: serverErrors[key]
                    })
                })
            },
            onFinish: () => setLoading(false)
        })
    }

    return (
        <div style={{ padding: 20, minHeight: '80vh', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
            <div style={{ textAlign: 'center', marginBottom: 32 }}>
                <h1 style={{ fontSize: 28, fontWeight: 700, margin: '0 0 8px' }}>{t('Create an account')}</h1>
                <p style={{ color: '#666', margin: 0, fontSize: 15 }}>{t('Book appointments and manage your health')}</p>
            </div>

            <MobileCard style={{ borderRadius: 16 }}>
                <MobileForm
                    layout="vertical"
                    onFinish={handleSubmit(onSubmit)}
                    footer={
                        <MobileButton
                            block
                            type="submit"
                            color="primary"
                            size="large"
                            loading={loading}
                            style={{ '--border-radius': '8px' }}
                        >
                            {t('Create Patient Account')}
                        </MobileButton>
                    }
                >
                    <div style={{ display: 'flex', gap: 12 }}>
                        <MobileForm.Item
                            label={t('First name')}
                            style={{ flex: 1 }}
                            help={errors.first_name?.message}
                        // antd-mobile Form validates status implicitly if we don't pass 'validateStatus'
                        // but we are using RHF, so we just show 'help'
                        >
                            <Controller
                                name="first_name"
                                control={control}
                                render={({ field }) => (
                                    <MobileInput {...field} placeholder="John" clearable />
                                )}
                            />
                        </MobileForm.Item>

                        <MobileForm.Item
                            label={t('Last name')}
                            style={{ flex: 1 }}
                            help={errors.last_name?.message}
                        >
                            <Controller
                                name="last_name"
                                control={control}
                                render={({ field }) => (
                                    <MobileInput {...field} placeholder="Doe" clearable />
                                )}
                            />
                        </MobileForm.Item>
                    </div>

                    <MobileForm.Item
                        label={t('Email address')}
                        help={errors.email?.message}
                    >
                        <Controller
                            name="email"
                            control={control}
                            render={({ field }) => (
                                <MobileInput {...field} placeholder="you@medic.com" clearable />
                            )}
                        />
                    </MobileForm.Item>

                    <MobileForm.Item
                        label={t('Password')}
                        help={errors.password?.message}
                    >
                        <Controller
                            name="password"
                            control={control}
                            render={({ field }) => (
                                <MobileInput {...field} type="password" placeholder={t('Min. 8 characters')} clearable />
                            )}
                        />
                    </MobileForm.Item>
                </MobileForm>
            </MobileCard>

            <p style={{ textAlign: 'center', marginTop: 20, fontSize: 14 }}>
                {t('Are you a doctor?')}{' '}
                <a onClick={() => router.visit('/register/doctor')} style={{ fontWeight: 600, color: '#0d9488' }}>
                    {t('Register as a Specialist')}
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
// DESKTOP REGISTER
// =============================================================================

function DesktopRegisterPage() {
    const { t } = useTranslation('default')
    const [loading, setLoading] = useState(false)

    const { control, handleSubmit, setError, formState: { errors } } = useForm<RegisterFormData>({
        resolver: zodResolver(registerSchema),
        defaultValues: {
            first_name: '',
            last_name: '',
            email: '',
            password: ''
        }
    })

    const onSubmit = (data: RegisterFormData) => {
        if (loading) return
        setLoading(true)

        router.post('/register', data, {
            onError: (serverErrors) => {
                setLoading(false)
                Object.keys(serverErrors).forEach((key) => {
                    setError(key as keyof RegisterFormData, {
                        type: 'server',
                        message: serverErrors[key]
                    })
                })
            },
            onFinish: () => setLoading(false)
        })
    }

    return (
        <div style={{ maxWidth: 400, margin: '80px auto' }}>
            <Flex vertical align="center" style={{ marginBottom: 32 }}>
                <Title level={1}>{t('Create an account')}</Title>
                <Text type="secondary">{t('Book appointments and manage your health')}</Text>
            </Flex>

            <DesktopCard bordered style={{ padding: 24 }}>
                <form onSubmit={handleSubmit(onSubmit)}>
                    <Flex vertical gap="middle">
                        <Row gutter={16}>
                            <Col span={12}>
                                <Controller
                                    name="first_name"
                                    control={control}
                                    render={({ field }) => (
                                        <Form.Item
                                            validateStatus={errors.first_name ? 'error' : ''}
                                            help={errors.first_name?.message}
                                            style={{ marginBottom: 0 }}
                                        >
                                            <div style={{ marginBottom: 8 }}><Text strong>{t('First name')}</Text></div>
                                            <DesktopInput {...field} placeholder="John" />
                                        </Form.Item>
                                    )}
                                />
                            </Col>
                            <Col span={12}>
                                <Controller
                                    name="last_name"
                                    control={control}
                                    render={({ field }) => (
                                        <Form.Item
                                            validateStatus={errors.last_name ? 'error' : ''}
                                            help={errors.last_name?.message}
                                            style={{ marginBottom: 0 }}
                                        >
                                            <div style={{ marginBottom: 8 }}><Text strong>{t('Last name')}</Text></div>
                                            <DesktopInput {...field} placeholder="Doe" />
                                        </Form.Item>
                                    )}
                                />
                            </Col>
                        </Row>

                        <Controller
                            name="email"
                            control={control}
                            render={({ field }) => (
                                <Form.Item
                                    validateStatus={errors.email ? 'error' : ''}
                                    help={errors.email?.message}
                                    style={{ marginBottom: 0 }}
                                >
                                    <div style={{ marginBottom: 8 }}><Text strong>{t('Email address')}</Text></div>
                                    <DesktopInput {...field} placeholder="you@medic.com" />
                                </Form.Item>
                            )}
                        />

                        <Controller
                            name="password"
                            control={control}
                            render={({ field }) => (
                                <Form.Item
                                    validateStatus={errors.password ? 'error' : ''}
                                    help={errors.password?.message}
                                    style={{ marginBottom: 0 }}
                                >
                                    <div style={{ marginBottom: 8 }}><Text strong>{t('Password')}</Text></div>
                                    <DesktopInput.Password {...field} placeholder={t('Min. 8 characters')} />
                                </Form.Item>
                            )}
                        />

                        <DesktopButton type="primary" htmlType="submit" loading={loading} block size="large" style={{ marginTop: 24 }}>
                            {t('Create Patient Account')}
                        </DesktopButton>
                    </Flex>
                </form>
            </DesktopCard>

            <Text style={{ display: 'block', textAlign: 'center', marginTop: 16 }}>
                {t('Are you a doctor?')}{' '}
                <Link href="/register/doctor" style={{ fontWeight: 700 }}>
                    {t('Register as a Specialist')}
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

export default function RegisterPage() {
    const isMobile = useIsMobile()

    if (isMobile) {
        return <MobileRegisterPage />
    }

    return <DesktopRegisterPage />
}
