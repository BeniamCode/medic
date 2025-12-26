import { Table, Button, Input, Space } from 'antd'
import { SearchOutlined } from '@ant-design/icons'
import { router } from '@inertiajs/react'
import { useState } from 'react'
import AdminLayout from '@/layouts/AdminLayout'
import type { ColumnsType } from 'antd/es/table'

interface Patient {
    id: string
    first_name: string
    last_name: string
    email: string
    phone?: string
    date_of_birth?: string
    inserted_at: string
}

interface PatientsProps {
    patients: Patient[]
    pagination: {
        current_page: number
        per_page: number
        total: number
    }
    search?: string
}

export default function AdminPatients({ patients, pagination, search }: PatientsProps) {
    const [searchValue, setSearchValue] = useState(search || '')

    const handleSearch = () => {
        router.get('/medic/patients', { search: searchValue })
    }

    const columns: ColumnsType<Patient> = [
        {
            title: 'Name',
            key: 'name',
            render: (_, record) => `${record.first_name} ${record.last_name}`,
        },
        {
            title: 'Email',
            dataIndex: 'email',
            key: 'email',
        },
        {
            title: 'Phone',
            dataIndex: 'phone',
            key: 'phone',
            render: (phone?: string) => phone || '—',
        },
        {
            title: 'Date of Birth',
            dataIndex: 'date_of_birth',
            key: 'date_of_birth',
            render: (dob?: string) => (dob ? new Date(dob).toLocaleDateString() : '—'),
        },
        {
            title: 'Joined',
            dataIndex: 'inserted_at',
            key: 'inserted_at',
            render: (date: string) => new Date(date).toLocaleDateString(),
        },
    ]

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>Patient Management</h1>
            </div>

            <div style={{ marginBottom: 16 }}>
                <Space>
                    <Input
                        placeholder="Search by name or email"
                        prefix={<SearchOutlined />}
                        value={searchValue}
                        onChange={(e) => setSearchValue(e.target.value)}
                        onPressEnter={handleSearch}
                        style={{ width: 300 }}
                        allowClear
                    />
                    <Button type="primary" onClick={handleSearch}>
                        Search
                    </Button>
                </Space>
            </div>

            <Table
                columns={columns}
                dataSource={patients}
                rowKey="id"
                pagination={{
                    current: pagination.current_page,
                    pageSize: pagination.per_page,
                    total: pagination.total,
                    onChange: (page) => router.get('/medic/patients', { page, search: searchValue }),
                }}
            />
        </div>
    )
}

AdminPatients.layout = (page: React.ReactElement) => <AdminLayout>{page}</AdminLayout>
