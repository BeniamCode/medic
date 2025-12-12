import {
    Button,
    Card,
    Checkbox,
    Input,
    Typography,
    Form,
    Flex
} from 'antd'
import { Link, useForm } from '@inertiajs/react'
import { FormEvent } from 'react'
import { LockOutlined, MailOutlined } from '@ant-design/icons'

const { Title, Text, Link: AntLink } = Typography

export default function LoginPage() {
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

            <Card bordered shadow="always" style={{ padding: 24 }}>
                <form onSubmit={submit}>
                    <Flex vertical gap="middle">
                        <Form.Item
                            validateStatus={errors.email ? 'error' : ''}
                            help={errors.email}
                            style={{ marginBottom: 0 }}
                        >
                            <div style={{ marginBottom: 8 }}><Text strong>Email address</Text></div>
                            <Input
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
                            <Input.Password
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

                        <Button type="primary" htmlType="submit" loading={processing} block size="large" style={{ marginTop: 24 }}>
                            Sign in
                        </Button>
                    </Flex>
                </form>
            </Card>

            <Text style={{ display: 'block', textAlign: 'center', marginTop: 16 }}>
                Don&apos;t have an account?{' '}
                <Link href="/register" style={{ fontWeight: 700 }}>
                    Register
                </Link>
            </Text>
        </div>
    )
}
