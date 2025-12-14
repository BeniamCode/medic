import {
    App as AntdApp,
    Layout,
    Button,
    Avatar,
    Dropdown,
    Badge,
    Typography,
    theme,
    Space,
    Flex,
    MenuProps,
    Drawer
} from 'antd'
import { Link, usePage } from '@inertiajs/react'
import {
    IconBell,
    IconCalendar,
    IconCalendarEvent,
    IconHome,
    IconLogout,
    IconMoon,
    IconSearch,
    IconSettings,
    IconSun,
    IconUserCircle,
    IconMenu2
} from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import { SharedAppProps } from '@/types/app'
import { useEffect, useState } from 'react'
import { useThemeMode } from '@/app'
import { ensureNotificationsStream } from '@/lib/notificationsStream'

const { Header, Sider, Content } = Layout
const { Text } = Typography

interface AppLayoutProps {
    children: React.ReactNode
}

export default function AppLayout({ children }: AppLayoutProps) {
    const [mobileOpen, setMobileOpen] = useState(false)
    const { auth, app, flash } = usePage<SharedAppProps>().props
    const { url } = usePage()
    const path = url.split('?')[0]

    const { notification } = AntdApp.useApp()

    const [unreadCount, setUnreadCount] = useState<number>(app.unreadCount || 0)

    useEffect(() => {
        setUnreadCount(app.unreadCount || 0)
    }, [app.unreadCount])

    useEffect(() => {
        if (!auth.authenticated) {
            ensureNotificationsStream().stop()
            setUnreadCount(0)
            return
        }

        ensureNotificationsStream().start()

        const onUnread = (ev: Event) => {
            const detail = (ev as CustomEvent).detail as { unreadCount?: number } | undefined
            if (detail && typeof detail.unreadCount === 'number') {
                setUnreadCount(detail.unreadCount)
            }
        }

        const onNew = (ev: Event) => {
            const detail = (ev as CustomEvent).detail as { title?: string; message?: string } | undefined
            if (!detail) return

            notification.info({
                message: detail.title || 'Notification',
                description: detail.message || '',
                placement: 'topRight'
            })
        }

        window.addEventListener('medic:notifications:unreadCount', onUnread)
        window.addEventListener('medic:notifications:new', onNew)

        return () => {
            window.removeEventListener('medic:notifications:unreadCount', onUnread)
            window.removeEventListener('medic:notifications:new', onNew)
        }
    }, [auth.authenticated, notification])

    // Flash Message Handling (using AntD notification is better but for now let's use the hook in a simpler way if needed, or just standard Antd static methods)
    // Actually we need to verify if `App` component provides context for message/notification.
    // In `app.tsx` we wrapped with `AntApp`, so we can use `App.useApp()` to get message/notification api.
    // However, since we are inside `AppLayout` which is inside `App`, we can use the static methods or hooks.
    // Let's use `App.useApp()` if possible or just `notification` static.
    // But `AntApp` (from 'antd') provides context.

    // NOTE: In AntD v5, using static methods (notification.open) works outside context but inside App is better to use hook.
    // But to use hook we need to be deeper. `AppLayout` IS deep enough.
    // Let's try to stick to standard static if easier, or use `App.useApp()`.
    // Actually, let's keep it simple.

    const user = auth.user
    const isDoctor = user?.role === 'doctor'
    // Theme mode handling might need adjustment as AntD handles it differently, but we have our own context.
    // We might need to update the actual AntD theme config in `app.tsx` based on this context.
    const { colorScheme, toggleColorScheme } = useThemeMode()

    const showNavbar = !!user
    const { t } = useTranslation()

    const {
        token: { colorBgContainer, colorBorderSecondary },
    } = theme.useToken()

    const userMenu: MenuProps = {
        items: [
            {
                key: 'settings',
                label: <Link href="/settings">Settings</Link>,
                icon: <IconSettings size={14} />
            },
            {
                type: 'divider'
            },
            {
                key: 'logout',
                label: (
                    <Link href="/logout" method="delete" as="button" className="w-full text-left">
                        Logout
                    </Link>
                ),
                icon: <IconLogout size={14} />,
                danger: true
            }
        ]
    }

    const NavContent = () => (
        <Flex vertical gap="small" className="h-full">
            <Link href="/">
                <Button
                    type={path === '/' ? 'primary' : 'text'}
                    ghost={path === '/'}
                    className={path === '/' ? 'bg-teal-50 text-teal-700' : ''}
                    block
                    style={{ justifyContent: 'flex-start' }}
                    icon={<IconHome size={20} />}
                >
                    Home
                </Button>
            </Link>

            {isDoctor ? (
                <>
                    <Text type="secondary" style={{ fontSize: '11px', fontWeight: 700, marginTop: 16, marginBottom: 8, textTransform: 'uppercase' }}>Practice</Text>
                    <Link href="/dashboard/doctor">
                        <Button
                            type={path.startsWith('/dashboard/doctor') && !path.includes('profile') ? 'primary' : 'text'}
                            ghost={path.startsWith('/dashboard/doctor') && !path.includes('profile')}
                            className={path.startsWith('/dashboard/doctor') && !path.includes('profile') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: 'flex-start' }}
                            icon={<IconHome size={20} />}
                        >
                            Dashboard
                        </Button>
                    </Link>
                    <Link href="/dashboard/doctor/appointments">
                        <Button
                            type={path.startsWith('/dashboard/doctor/appointments') ? 'primary' : 'text'}
                            ghost={path.startsWith('/dashboard/doctor/appointments')}
                            className={path.startsWith('/dashboard/doctor/appointments') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: 'flex-start' }}
                            icon={<IconCalendarEvent size={20} />}
                        >
                            Appointments
                        </Button>
                    </Link>
                    <Link href="/doctor/schedule">
                        <Button
                            type={path.startsWith('/doctor/schedule') ? 'primary' : 'text'}
                            ghost={path.startsWith('/doctor/schedule')}
                            className={path.startsWith('/doctor/schedule') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: 'flex-start' }}
                            icon={<IconCalendarEvent size={20} />}
                        >
                            My Schedule
                        </Button>
                    </Link>
                    <Link href="/dashboard/doctor/profile">
                        <Button
                            type={path.includes('/doctor/profile') ? 'primary' : 'text'}
                            ghost={path.includes('/doctor/profile')}
                            className={path.includes('/doctor/profile') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: 'flex-start' }}
                            icon={<IconUserCircle size={20} />}
                        >
                            My Profile
                        </Button>
                    </Link>
                    <Link href="/notifications">
                        <Button
                            type={path.startsWith('/notifications') ? 'primary' : 'text'}
                            ghost={path.startsWith('/notifications')}
                            className={path.startsWith('/notifications') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: 'flex-start' }}
                            icon={<IconBell size={20} />}
                        >
                            Notifications
                        </Button>
                    </Link>
                </>
            ) : (
                <>
                    <Text type="secondary" style={{ fontSize: '11px', fontWeight: 700, marginTop: 16, marginBottom: 8, textTransform: 'uppercase' }}>Patient</Text>
                    <Link href="/dashboard">
                        <Button
                            type={path === '/dashboard' ? 'primary' : 'text'}
                            ghost={path === '/dashboard'}
                            className={path === '/dashboard' ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: 'flex-start' }}
                            icon={<IconCalendar size={20} />}
                        >
                            Appointments
                        </Button>
                    </Link>

                    <Link href="/dashboard/patient/profile">
                        <Button
                            type={path.startsWith('/dashboard/patient/profile') ? 'primary' : 'text'}
                            ghost={path.startsWith('/dashboard/patient/profile')}
                            className={path.startsWith('/dashboard/patient/profile') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: 'flex-start' }}
                            icon={<IconUserCircle size={20} />}
                        >
                            My Profile
                        </Button>
                    </Link>

                    <Link href="/notifications">
                        <Button
                            type={path.startsWith('/notifications') ? 'primary' : 'text'}
                            ghost={path.startsWith('/notifications')}
                            className={path.startsWith('/notifications') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: 'flex-start' }}
                            icon={<IconBell size={20} />}
                        >
                            Notifications
                        </Button>
                    </Link>
                </>
            )}

            <Text type="secondary" style={{ fontSize: '11px', fontWeight: 700, marginTop: 16, marginBottom: 8, textTransform: 'uppercase' }}>Discover</Text>
            <Link href="/search">
                <Button
                    type={path === '/search' ? 'text' : 'text'} // 'primary' if active, but search is usually secondary
                    className={path === '/search' ? 'bg-gray-100' : ''}
                    block
                    style={{ justifyContent: 'flex-start' }}
                    icon={<IconSearch size={20} />}
                >
                    Find Doctors
                </Button>
            </Link>
        </Flex>
    )

    return (
        <Layout style={{ minHeight: '100vh' }}>
            <Header style={{
                background: colorBgContainer,
                borderBottom: `1px solid ${colorBorderSecondary}`,
                padding: '0 16px',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                height: 60,
                position: 'sticky',
                top: 0,
                zIndex: 1000
            }}>
                <Flex align="center" gap="middle">
                    {showNavbar && (
                        <Button
                            type="text"
                            icon={<IconMenu2 size={20} />}
                            onClick={() => setMobileOpen(true)}
                            className="md:hidden"
                        />
                    )}
                    <Link href="/" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <img
                            src="/images/logo-medic-sun.svg"
                            alt="Medic"
                            style={{ height: 32, width: 'auto', filter: colorScheme === 'dark' ? 'brightness(0) invert(1)' : undefined }}
                        />
                        <Badge count="Beta" color="blue" />
                    </Link>
                </Flex>

                <Flex align="center" gap="small">
                    <Button
                        type="text"
                        shape="circle"
                        icon={colorScheme === 'dark' ? <IconSun size={18} /> : <IconMoon size={18} />}
                        onClick={toggleColorScheme}
                    />

                    {user ? (
                        <>
                            <Link href="/notifications">
                                <Badge count={unreadCount} size="small" overflowCount={9}>
                                    <Button type="text" shape="circle" icon={<IconBell size={20} />} />
                                </Badge>
                            </Link>
                            <Dropdown menu={userMenu} placement="bottomRight" trigger={['click']}>
                                <Button type="text" style={{ padding: '4px 8px', height: 'auto' }}>
                                    <Flex align="center" gap="small">
                                        <Avatar src={user.profileImageUrl} style={{ backgroundColor: '#0D9488' }}>
                                            {user.firstName?.[0]}
                                        </Avatar>
                                        <div className="hidden sm:block text-left">
                                            <Text strong style={{ display: 'block', lineHeight: 1.2 }}>{user.firstName} {user.lastName}</Text>
                                            <Text type="secondary" style={{ fontSize: 12 }}>{user.email}</Text>
                                        </div>
                                    </Flex>
                                </Button>
                            </Dropdown>
                        </>
                    ) : (
                        <Space>
                            <Link href="/login">
                                <Button type="text">Sign in</Button>
                            </Link>
                            <Link href="/register">
                                <Button type="primary">Sign up</Button>
                            </Link>
                        </Space>
                    )}
                </Flex>
            </Header>

            <Layout>
                {showNavbar && (
                    <>
                        {/* Desktop Sidebar */}
                        <Sider
                            width={300}
                            theme="light"
                            breakpoint="sm"
                            collapsedWidth="0"
                            trigger={null}
                            style={{
                                background: colorBgContainer,
                                borderRight: `1px solid ${colorBorderSecondary}`,
                                height: 'calc(100vh - 60px)',
                                position: 'sticky',
                                top: 60,
                                overflowY: 'auto'
                            }}
                            className="hidden md:block"
                        >
                            <div style={{ padding: 16 }}>
                                <NavContent />
                            </div>
                        </Sider>

                        {/* Mobile Drawer */}
                        <Drawer
                            placement="left"
                            onClose={() => setMobileOpen(false)}
                            open={mobileOpen}
                            width={300}
                            styles={{ body: { padding: 16 } }}
                        >
                            <NavContent />
                        </Drawer>
                    </>
                )}

                <Content style={{ padding: 16, maxWidth: 1280, width: '100%', margin: '0 auto' }}>
                    {children}
                </Content>
            </Layout>
        </Layout>
    )
}
