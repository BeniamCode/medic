import React from 'react'
import { Link, router, usePage } from '@inertiajs/react'
import { Table, Button, Space, Tag, Card } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import AdminLayout from '@/layouts/AdminLayout'

interface EmailTemplate {
    id: string
    name: string
    subject: string
    sender_name: string
    sender_address: string
    description?: string
    inserted_at: string
}

interface IndexProps {
    templates: EmailTemplate[]
}

const EmailTemplatesIndex = ({ templates }: IndexProps) => {
    const columns = [
        {
            title: 'Name',
            dataIndex: 'name',
            key: 'name',
            render: (text: string, record: EmailTemplate) => (
                <div>
                    <div style={{ fontWeight: 600 }}>{text}</div>
                    <div style={{ fontSize: 12, color: '#888' }}>{record.description}</div>
                </div>
            )
        },
        {
            title: 'Subject',
            dataIndex: 'subject',
            key: 'subject',
        },
        {
            title: 'Sender',
            key: 'sender',
            render: (_: any, record: EmailTemplate) => (
                <span>{record.sender_name} &lt;{record.sender_address}&gt;</span>
            )
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, record: EmailTemplate) => (
                <Space>
                    <Link href={`/medic/email_templates/${record.id}/edit`}>
                        <Button size="small" icon={<EditOutlined />}>Edit</Button>
                    </Link>
                </Space>
            )
        }
    ]

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>Email Templates</h1>
                <Link href="/medic/email_templates/new">
                    <Button type="primary" icon={<PlusOutlined />}>New Template</Button>
                </Link>
            </div>

            <Card title="Email Debugger" style={{ marginBottom: 24 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                    <Button
                        onClick={() => router.post('/medic/email_debug/send', { to: 'dbeniam@gmail.com', from_type: 'default' })}
                    >
                        Send Test (hi@medic.gr)
                    </Button>
                    <Button
                        onClick={() => router.post('/medic/email_debug/send', { to: 'dbeniam@gmail.com', from_type: 'appointments' })}
                    >
                        Send Test (appointments@medic.gr)
                    </Button>
                    <span style={{ color: '#888', fontSize: 12 }}>Sends "Hello World" to dbeniam@gmail.com</span>
                </div>
            </Card>

            <Card>
                <Table dataSource={templates} columns={columns} rowKey="id" pagination={{ pageSize: 20 }} />
            </Card>
        </div>
    )
}

EmailTemplatesIndex.layout = (page: React.ReactNode) => <AdminLayout>{page}</AdminLayout>

export default EmailTemplatesIndex
