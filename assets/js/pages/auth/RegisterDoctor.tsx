import {
    Button,
    Card,
    Input,
    Typography,
    Form,
    Flex,
    Row,
    Col
} from 'antd'
import { Link, useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

const { Title, Text } = Typography

export default function RegisterDoctorPage() {
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

            <Card bordered shadow="always" style={{ padding: 24 }}>
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
                                    <Input
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
                                    <Input
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
                            <Input
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
                            <Input.Password
                                placeholder="Min. 8 characters"
                                value={data.password}
                                onChange={(e) => setData('password', e.target.value)}
                            />
                        </Form.Item>

                        <Button type="primary" htmlType="submit" loading={processing} block size="large" style={{ marginTop: 24 }}>
                            Start Application
                        </Button>
                    </Flex>
                </form>
            </Card>

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
