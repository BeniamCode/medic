import { Table, Button, Input, Space, Tag, Popconfirm, message } from 'antd'
import { DeleteOutlined, SearchOutlined, CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons'
import { router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import AdminLayout from '@/layouts/AdminLayout'
import type { ColumnsType } from 'antd/es/table'

interface User {
    id: string
    email: string
    role: string
    confirmed: boolean
    confirmed_at?: string
    first_name?: string
    last_name?: string
    inserted_at: string
}

interface UsersProps {
    users: User[]
    pagination: {
        current_page: number
        per_page: number
        total: number
    }
    search?: string
}

export default function AdminUsers({ users, pagination, search }: UsersProps) {
    const [searchValue, setSearchValue] = useState(search || '')

    const handleDelete = (userId: string) => {
        const token = (window as any).__getCSRFToken?.() || document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''
        router.delete(`/medic/users/${userId}`, {
            headers: { 'X-CSRF-Token': token },
            onSuccess: () => message.success('User deleted successfully'),
            onError: () => message.error('Failed to delete user'),
        })
    }

    const handleSearch = () => {
        router.get('/medic/users', { search: searchValue })
    }

    const columns: ColumnsType<User> = [
        {
            title: 'Email',
            dataIndex: 'email',
            key: 'email',
        },
        {
            title: 'Name',
            key: 'name',
            render: (_, record) => (
                <span>
                    {record.first_name && record.last_name
                        ? `${record.first_name} ${record.last_name}`
                        : '—'}
                </span>
            ),
        },
        {
            title: 'Role',
            dataIndex: 'role',
            key: 'role',
            render: (role: string) => (
                <Tag color={role === 'admin' ? 'red' : role === 'doctor' ? 'blue' : 'green'}>
                    {role.toUpperCase()}
                </Tag>
            ),
        },
        {
            title: 'Confirmed',
            dataIndex: 'confirmed',
            key: 'confirmed',
            render: (confirmed: boolean) =>
                confirmed ? (
                    <CheckCircleOutlined style={{ color: '#52c41a', fontSize: 18 }} />
                ) : (
                    <CloseCircleOutlined style={{ color: '#ff4d4f', fontSize: 18 }} />
                ),
        },
        {
            title: 'Joined',
            dataIndex: 'inserted_at',
            key: 'inserted_at',
            render: (date: string) => new Date(date).toLocaleDateString(),
        },
        {
            title: 'Actions',
            key: 'actions',
            render: (_, record) => (
                <Popconfirm
                    title="Delete user"
                    description="Are you sure you want to delete this user? This action cannot be undone."
                    onConfirm={() => handleDelete(record.id)}
                    okText="Yes, delete"
                    cancelText="Cancel"
                    okButtonProps={{ danger: true }}
                >
                    <Button danger type="text" icon={<DeleteOutlined />}>
                        Delete
                    </Button>
                </Popconfirm>
            ),
        },
    ]

    return (
        <div>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
                <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>User Management</h1>
            </div>

            <div style={{ marginBottom: 16 }}>
                <Space>
                    <Input
                        placeholder="Search by email or name"
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
                dataSource={users}
                rowKey="id"
                pagination={{
                    current: pagination.current_page,
                    pageSize: pagination.per_page,
                    total: pagination.total,
                    onChange: (page) => router.get('/medic/users', { page, search: searchValue }),
                }}
            />
        </div>
    )
}

AdminUsers.layout = (page: React.ReactElement) => <AdminLayout>{page}</AdminLayout>
