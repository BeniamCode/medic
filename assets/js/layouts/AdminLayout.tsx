import { Layout, Menu, Dropdown, Avatar, Button, Space, Typography } from 'antd'
import {
    DashboardOutlined,
    UserOutlined,
    TeamOutlined,
    CalendarOutlined,
    StarOutlined,
    DollarOutlined,
    LogoutOutlined,
    DownOutlined
} from '@ant-design/icons'
import { Link, router, usePage } from '@inertiajs/react'
import { ReactNode } from 'react'

const { Header, Sider, Content } = Layout
const { Text } = Typography

interface AdminLayoutProps {
    children: ReactNode
}

export default function AdminLayout({ children }: AdminLayoutProps) {
    const { app, auth } = usePage().props as any
    const currentPath = app?.path || '/medic/dashboard'

    const menuItems = [
        {
            key: '/medic/dashboard',
            icon: <DashboardOutlined />,
            label: <Link href="/medic/dashboard">Dashboard</Link>,
        },
        {
            key: '/medic/users',
            icon: <UserOutlined />,
            label: <Link href="/medic/users">Users</Link>,
        },
        {
            key: '/medic/doctors',
            icon: <TeamOutlined />,
            label: <Link href="/medic/doctors">Doctors</Link>,
        },
        {
            key: '/medic/patients',
            icon: <TeamOutlined />,
            label: <Link href="/medic/patients">Patients</Link>,
        },
        {
            key: '/medic/appointments',
            icon: <CalendarOutlined />,
            label: <Link href="/medic/appointments">Appointments</Link>,
        },
        {
            key: '/medic/reviews',
            icon: <StarOutlined />,
            label: <Link href="/medic/reviews">Reviews</Link>,
        },
        {
            key: '/medic/financials',
            icon: <DollarOutlined />,
            label: <Link href="/medic/financials">Financials</Link>,
        },
        {
            key: 'emails',
            icon: <CalendarOutlined />, // Re-using calendar or maybe MailOutlined if available
            label: 'Emails',
            children: [
                {
                    key: '/medic/email_templates',
                    label: <Link href="/medic/email_templates">Templates</Link>,
                },
                {
                    key: '/medic/email_logs',
                    label: <Link href="/medic/email_logs">Logs</Link>,
                },
            ]
        },
    ]

    const handleLogout = () => {
        const token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''
        router.delete('/medic/logout', { headers: { 'X-CSRF-Token': token } })
    }

    const userMenuItems = [
        {
            key: 'logout',
            icon: <LogoutOutlined />,
            label: 'Logout',
            onClick: handleLogout,
        },
    ]

    return (
        <Layout style={{ minHeight: '100vh' }}>
            <Sider
                theme="light"
                style={{
                    boxShadow: '2px 0 8px rgba(0,0,0,0.1)',
                    position: 'fixed',
                    left: 0,
                    top: 0,
                    bottom: 0,
                    overflow: 'auto',
                }}
            >
                <div
                    style={{
                        height: 64,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        borderBottom: '1px solid #f0f0f0',
                    }}
                >
                    <Text strong style={{ fontSize: 18, color: '#0d9488' }}>
                        Medic Admin
                    </Text>
                </div>
                <Menu
                    mode="inline"
                    selectedKeys={[currentPath]}
                    items={menuItems}
                    style={{ borderRight: 0 }}
                />
            </Sider>

            <Layout style={{ marginLeft: 200 }}>
                <Header
                    style={{
                        padding: '0 24px',
                        background: '#fff',
                        display: 'flex',
                        justifyContent: 'flex-end',
                        alignItems: 'center',
                        boxShadow: '0 1px 4px rgba(0,0,0,0.08)',
                        position: 'sticky',
                        top: 0,
                        zIndex: 999,
                    }}
                >
                    <Dropdown menu={{ items: userMenuItems }} placement="bottomRight">
                        <Space style={{ cursor: 'pointer' }}>
                            <Avatar icon={<UserOutlined />} />
                            <Text>{auth?.user?.first_name || 'Admin'}</Text>
                            <DownOutlined style={{ fontSize: 12 }} />
                        </Space>
                    </Dropdown>
                </Header>

                <Content
                    style={{
                        margin: '24px 16px',
                        padding: 24,
                        background: '#fff',
                        borderRadius: 8,
                        minHeight: 280,
                    }}
                >
                    {children}
                </Content>
            </Layout>
        </Layout>
    )
}
