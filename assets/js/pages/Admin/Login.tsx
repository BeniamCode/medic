import { Button, Card, Form, Input, Typography, message } from 'antd'
import { LockOutlined, UserOutlined } from '@ant-design/icons'
import { useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

const { Title, Text } = Typography

interface LoginProps {
    errors?: {
        email?: string
        password?: string
    }
}

export default function AdminLogin({ errors }: LoginProps) {
    const { data, setData, post, processing } = useForm({
        email: '',
        password: '',
    })

    const handleSubmit = (e: FormEvent) => {
        e.preventDefault()
        post('/medic/login')
    }

    return (
        <div
            style={{
                minHeight: '100vh',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
            }}
        >
            <Card
                style={{
                    width: 400,
                    boxShadow: '0 10px 40px rgba(0,0,0,0.1)',
                    borderRadius: 8,
                }}
            >
                <div style={{ textAlign: 'center', marginBottom: 32 }}>
                    <Title level={2} style={{ marginBottom: 8 }}>
                        Admin Panel
                    </Title>
                    <Text type="secondary">Sign in to access the admin dashboard</Text>
                </div>

                <form onSubmit={handleSubmit}>
                    <Form.Item
                        validateStatus={errors?.email ? 'error' : ''}
                        help={errors?.email}
                    >
                        <Input
                            size="large"
                            prefix={<UserOutlined />}
                            placeholder="Email"
                            value={data.email}
                            onChange={(e) => setData('email', e.target.value)}
                            disabled={processing}
                        />
                    </Form.Item>

                    <Form.Item
                        validateStatus={errors?.password ? 'error' : ''}
                        help={errors?.password}
                    >
                        <Input.Password
                            size="large"
                            prefix={<LockOutlined />}
                            placeholder="Password"
                            value={data.password}
                            onChange={(e) => setData('password', e.target.value)}
                            disabled={processing}
                        />
                    </Form.Item>

                    <Form.Item style={{ marginBottom: 0 }}>
                        <Button
                            type="primary"
                            htmlType="submit"
                            size="large"
                            block
                            loading={processing}
                        >
                            Sign In
                        </Button>
                    </Form.Item>
                </form>

                <div style={{ marginTop: 16, textAlign: 'center' }}>
                    <Text type="secondary" style={{ fontSize: 12 }}>
                        Admin access only • Contact support for assistance
                    </Text>
                </div>
            </Card>
        </div>
    )
}
