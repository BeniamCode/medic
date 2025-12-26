import { Table, Card, Tag, Button, Tooltip, message } from 'antd'
import { ReloadOutlined } from '@ant-design/icons'
import { router } from '@inertiajs/react'
import AdminLayout from '@/layouts/AdminLayout'
import dayjs from 'dayjs'

interface EmailLog {
    id: string
    to: string
    subject: string
    template_name: string
    status: 'sent' | 'failed'
    error?: string
    triggered_by: string
    inserted_at: string
}

interface IndexProps {
    logs: EmailLog[]
}

const EmailLogsIndex = ({ logs }: IndexProps) => {
    const columns = [
        {
            title: 'Time',
            dataIndex: 'inserted_at',
            key: 'inserted_at',
            render: (text: string) => <span style={{ whiteSpace: 'nowrap' }}>{dayjs(text).format('YYYY-MM-DD HH:mm:ss')}</span>,
            sorter: (a: EmailLog, b: EmailLog) => dayjs(a.inserted_at).unix() - dayjs(b.inserted_at).unix(),
        },
        {
            title: 'To',
            dataIndex: 'to',
            key: 'to',
        },
        {
            title: 'Template',
            dataIndex: 'template_name',
            key: 'template_name',
            render: (text: string) => <Tag>{text}</Tag>
        },
        {
            title: 'Subject',
            dataIndex: 'subject',
            key: 'subject',
            ellipsis: true
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            render: (status: string, record: EmailLog) => (
                <Tag color={status === 'sent' ? 'green' : 'red'}>
                    {status.toUpperCase()}
                </Tag>
            )
        },
        {
            title: 'Error',
            dataIndex: 'error',
            key: 'error',
            render: (text: string) => text ? <span style={{ color: 'red', fontSize: 12 }}>{text}</span> : '-'
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_: any, record: EmailLog) => (
                <Tooltip title="Resend this email (uses saved body)">
                    <Button
                        size="small"
                        icon={<ReloadOutlined />}
                        onClick={() => {
                            if (confirm('Resend this email?')) {
                                router.post(`/medic/email_logs/${record.id}/resend`)
                            }
                        }}
                    >
                        Resend
                    </Button>
                </Tooltip>
            )
        }
    ]

    return (
        <div>
            <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 24 }}>Email Logs</h1>

            <Card>
                <Table
                    dataSource={logs}
                    columns={columns}
                    rowKey="id"
                    pagination={{ pageSize: 20 }}
                />
            </Card>
        </div>
    )
}

EmailLogsIndex.layout = (page: React.ReactNode) => <AdminLayout>{page}</AdminLayout>

export default EmailLogsIndex
