import { Table, Button, Input, Select, Space, Tag, message } from 'antd'
import { SearchOutlined, CheckCircleOutlined, CloseCircleOutlined } from '@ant-design/icons'
import { router } from '@inertiajs/react'
import { useState } from 'react'
import AdminLayout from '@/layouts/AdminLayout'
import type { ColumnsType } from 'antd/es/table'

interface Doctor {
    id: string
    first_name: string
    last_name: string
    email: string
    specialty?: string
    verified: boolean
    verified_at?: string
    inserted_at: string
}

interface DoctorsProps {
    doctors: Doctor[]
    pagination: {
        current_page: number
        per_page: number
        total: number
    }
    search?: string
    verified_filter?: string
}

export default function AdminDoctors({ doctors, pagination, search, verified_filter }: DoctorsProps) {
    const [searchValue, setSearchValue] = useState(search || '')
    const [selectedFilter, setSelectedFilter] = useState(verified_filter || 'all')

    const handleSearch = () => {
        router.get('/medic/doctors', {
            search: searchValue,
            verified: selectedFilter === 'all' ? undefined : selectedFilter
        })
    }

    const handleFilterChange = (value: string) => {
        setSelectedFilter(value)
        router.get('/medic/doctors', {
            search: searchValue,
            verified: value === 'all' ? undefined : value
        })
    }

    const columns: ColumnsType<Doctor> = [
        {
            title: 'Name',
            key: 'name',
            render: (_, record) => `Dr. ${record.first_name} ${record.last_name}`,
        },
        {
            title: 'Email',
            dataIndex: 'email',
            key: 'email',
        },
        {
            title: 'Specialty',
            dataIndex: 'specialty',
            key: 'specialty',
            render: (specialty?: string) => specialty || '—',
        },
        {
            title: 'Verified',
            dataIndex: 'verified',
            key: 'verified',
            render: (verified: boolean) =>
                verified ? (
                    <Tag color="green" icon={<CheckCircleOutlined />}>Verified</Tag>
                ) : (
                    <Tag color="orange" icon={<CloseCircleOutlined />}>Pending</Tag>
                ),
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
                <h1 style={{ fontSize: 24, fontWeight: 700, margin: 0 }}>Doctor Management</h1>
            </div>

            <div style={{ marginBottom: 16 }}>
                <Space>
                    <Input
                        placeholder="Search by name, email, or specialty"
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
                    <Select
                        value={selectedFilter}
                        onChange={handleFilterChange}
                        style={{ width: 150 }}
                        options={[
                            { label: 'All Doctors', value: 'all' },
                            { label: 'Verified', value: 'verified' },
                            { label: 'Pending', value: 'pending' },
                        ]}
                    />
                </Space>
            </div>

            <Table
                columns={columns}
                dataSource={doctors}
                rowKey="id"
                pagination={{
                    current: pagination.current_page,
                    pageSize: pagination.per_page,
                    total: pagination.total,
                    onChange: (page) =>
                        router.get('/medic/doctors', {
                            page,
                            search: searchValue,
                            verified: selectedFilter === 'all' ? undefined : selectedFilter,
                        }),
                }}
            />
        </div>
    )
}

AdminDoctors.layout = (page: React.ReactElement) => <AdminLayout>{page}</AdminLayout>
