import { Table, Button, Select, Space, Tag, Popconfirm, message } from 'antd'
import { CloseCircleOutlined } from '@ant-design/icons'
import { router } from '@inertiajs/react'
import { useState } from 'react'
import AdminLayout from '@/layouts/AdminLayout'
import type { ColumnsType } from 'antd/es/table'

interface Appointment {
    id: string
    patient_name: string
    doctor_name: string
    starts_at: string
    status: string
    duration_minutes: number
    consultation_mode?: string
    price_cents?: number
}

interface AppointmentsProps {
    appointments: Appointment[]
    pagination: {
        current_page: number
        per_page: number
        total: number
    }
    status_filter?: string
}

const statusColors: Record<string, string> = {
    pending: 'orange',
    confirmed: 'blue',
    completed: 'green',
    cancelled: 'red',
    'no-show': 'volcano',
}

export default function AdminAppointments({ appointments, pagination, status_filter }: AppointmentsProps) {
    const [selectedStatus, setSelectedStatus] = useState(status_filter || 'all')

    const handleStatusFilter = (status: string) => {
        setSelectedStatus(status)
        router.get('/medic/appointments', { status: status === 'all' ? undefined : status })
    }

    const handleCancel = (appointmentId: string) => {
        router.post(`/medic/appointments/${appointmentId}/cancel`, {}, {
            onSuccess: () => message.success('Appointment cancelled successfully'),
            onError: () => message.error('Failed to cancel appointment'),
        })
    }

    const columns: ColumnsType<Appointment> = [
        {
            title: 'Patient',
            dataIndex: 'patient_name',
            key: 'patient',
        },
        {
            title: 'Doctor',
            dataIndex: 'doctor_name',
            key: 'doctor',
        },
        {
            title: 'Date & Time',
            dataIndex: 'starts_at',
            key: 'starts_at',
            render: (date: string) => new Date(date).toLocaleString(),
        },
        {
            title: 'Duration',
            dataIndex: 'duration_minutes',
            key: 'duration',
            render: (mins: number) => `${mins} min`,
        },
        {
            title: 'Type',
            dataIndex: 'consultation_mode',
            key: 'mode',
            render: (mode?: string) => mode === 'telemedicine' ? 'Video' : 'In-Person',
        },
        {
            title: 'Status',
            dataIndex: 'status',
            key: 'status',
            render: (status: string) => (
                <Tag color={statusColors[status] || 'default'}>
                    {status.toUpperCase()}
                </Tag>
            ),
        },
        {
            title: 'Price',
            dataIndex: 'price_cents',
            key: 'price',
            render: (cents?: number) => cents ? `€${(cents / 100).toFixed(2)}` : '—',
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_, record) =>
                record.status !== 'cancelled' && record.status !== 'completed' ? (
                    <Popconfirm
                        title="Cancel appointment"
                        description="Are you sure you want to cancel this appointment?"
                        onConfirm={() => handleCancel(record.id)}
                        okText="Yes, cancel"
                        cancelText="No"
                        okButtonProps={{ danger: true }}
                    >
                        <Button danger type="text" icon={<CloseCircleOutlined />}>
                            Cancel
                        </Button>
                    </Popconfirm>
                ) : null,
        },
    ]

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>Appointment Management</h1>
            </div>

            <div style={{ marginBottom: 16 }}>
                <Space>
                    <span>Filter by status:</span>
                    <Select
                        value={selectedStatus}
                        onChange={handleStatusFilter}
                        style={{ width: 150 }}
                        options={[
                            { label: 'All', value: 'all' },
                            { label: 'Pending', value: 'pending' },
                            { label: 'Confirmed', value: 'confirmed' },
                            { label: 'Completed', value: 'completed' },
                            { label: 'Cancelled', value: 'cancelled' },
                        ]}
                    />
                </Space>
            </div>

            <Table
                columns={columns}
                dataSource={appointments}
                rowKey="id"
                pagination={{
                    current: pagination.current_page,
                    pageSize: pagination.per_page,
                    total: pagination.total,
                    onChange: (page) =>
                        router.get('/medic/appointments', {
                            page,
                            status: selectedStatus === 'all' ? undefined : selectedStatus,
                        }),
                }}
            />
        </div>
    )
}

AdminAppointments.layout = (page: React.ReactElement) => <AdminLayout>{page}</AdminLayout>
