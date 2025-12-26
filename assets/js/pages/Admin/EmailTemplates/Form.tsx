import React, { useState } from 'react'
import { Link, useForm } from '@inertiajs/react'
import { Form, Input, Button, Card, Space, Row, Col, Alert } from 'antd'
import { SaveOutlined, ArrowLeftOutlined } from '@ant-design/icons'
import AdminLayout from '@/layouts/AdminLayout'

interface EmailTemplate {
    id?: string
    name: string
    subject: string
    html_body: string
    text_body?: string
    sender_name: string
    sender_address: string
    description?: string
    variables?: Record<string, any>
}

interface FormProps {
    template?: EmailTemplate
    errors?: Record<string, string | string[]>
}

const EmailTemplateForm = ({ template, errors: serverErrors }: FormProps) => {
    const isEdit = !!template?.id
    const { data, setData, post, put, processing, errors, transform } = useForm({
        name: template?.name || '',
        subject: template?.subject || '',
        description: template?.description || '',
        sender_name: template?.sender_name || 'Medic',
        sender_address: template?.sender_address || 'hi@medic.gr',
        html_body: template?.html_body || '',
        text_body: template?.text_body || '',
        variables: JSON.stringify(template?.variables || {}, null, 2)
    })

    const handleSubmit = () => {
        transform((data) => ({
            ...data,
            variables: (() => {
                try {
                    return JSON.parse(data.variables)
                } catch (e) {
                    return {}
                }
            })()
        }))

        if (isEdit) {
            put(`/medic/email_templates/${template.id}`)
        } else {
            post('/medic/email_templates')
        }
    }

    return (
        <div>
            <div style={{ marginBottom: 24 }}>
                <Link href="/medic/email_templates">
                    <Button icon={<ArrowLeftOutlined />} type="text">Back to Templates</Button>
                </Link>
            </div>

            <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 24 }}>
                {isEdit ? `Edit Template: ${template.name}` : 'New Email Template'}
            </h1>

            {Object.keys(errors).length > 0 && (
                <Alert
                    message="Validation Error"
                    description="Please check the form fields."
                    type="error"
                    showIcon
                    style={{ marginBottom: 24 }}
                />
            )}

            <Form layout="vertical" onFinish={handleSubmit} initialValues={data}>
                <Row gutter={24}>
                    <Col span={16}>
                        <Card title="Content" bordered={false} style={{ marginBottom: 24 }}>
                            <Form.Item label="Subject" validateStatus={errors.subject ? 'error' : ''} help={errors.subject}>
                                <Input value={data.subject} onChange={e => setData('subject', e.target.value)} />
                            </Form.Item>

                            <Form.Item label="HTML Body" validateStatus={errors.html_body ? 'error' : ''} help={errors.html_body}>
                                <Input.TextArea
                                    value={data.html_body}
                                    onChange={e => setData('html_body', e.target.value)}
                                    rows={15}
                                    style={{ fontFamily: 'monospace' }}
                                />
                                <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>
                                    Supports {"{{ variable }}"} syntax.
                                </div>
                            </Form.Item>

                            <Form.Item label="Text Body (Optional)" validateStatus={errors.text_body ? 'error' : ''} help={errors.text_body}>
                                <Input.TextArea
                                    value={data.text_body}
                                    onChange={e => setData('text_body', e.target.value)}
                                    rows={10}
                                    style={{ fontFamily: 'monospace' }}
                                />
                            </Form.Item>
                        </Card>
                    </Col>

                    <Col span={8}>
                        <Card title="Settings" bordered={false} style={{ marginBottom: 24 }}>
                            <Form.Item label="Unique Name (ID)" validateStatus={errors.name ? 'error' : ''} help={errors.name}>
                                <Input
                                    value={data.name}
                                    onChange={e => setData('name', e.target.value)}
                                    disabled={isEdit}
                                    placeholder="e.g. appointment_confirmation"
                                />
                            </Form.Item>

                            <Form.Item label="Description">
                                <Input.TextArea value={data.description} onChange={e => setData('description', e.target.value)} rows={2} />
                            </Form.Item>

                            <Form.Item label="Sender Name">
                                <Input value={data.sender_name} onChange={e => setData('sender_name', e.target.value)} />
                            </Form.Item>

                            <Form.Item label="Sender Address">
                                <Input value={data.sender_address} onChange={e => setData('sender_address', e.target.value)} />
                            </Form.Item>

                            <Form.Item label="Default Variables (JSON)">
                                <Input.TextArea
                                    value={data.variables}
                                    onChange={e => setData('variables', e.target.value)}
                                    rows={6}
                                    style={{ fontFamily: 'monospace' }}
                                />
                                <div style={{ fontSize: 12, color: '#888', marginTop: 4 }}>
                                    Used for previews (not implemented yet) and defaults.
                                </div>
                            </Form.Item>
                        </Card>

                        <Button type="primary" htmlType="submit" icon={<SaveOutlined />} block loading={processing} size="large">
                            {isEdit ? 'Save Changes' : 'Create Template'}
                        </Button>
                    </Col>
                </Row>
            </Form>
        </div>
    )
}

EmailTemplateForm.layout = (page: React.ReactNode) => <AdminLayout>{page}</AdminLayout>

export default EmailTemplateForm
