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
import { Link, usePage, router } from '@inertiajs/react'
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
import { useIsMobile } from '@/lib/device'

// Mobile antd-mobile imports
import { TabBar, NavBar, Popup, List, SafeArea } from 'antd-mobile'
import {
    AppOutline,
    MessageOutline,
    UnorderedListOutline,
    UserOutline,
    SearchOutline,
    CalendarOutline,
    BellOutline,
    SetOutline
} from 'antd-mobile-icons'

const { Header, Sider, Content } = Layout
const { Text } = Typography

interface AppLayoutProps {
    children: React.ReactNode
}

export default function AppLayout({ children }: AppLayoutProps) {
    const isMobile = useIsMobile()
    const [mobileOpen, setMobileOpen] = useState(false)
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
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

    const user = auth.user
    const isDoctor = user?.role === 'doctor'
    const { colorScheme, toggleColorScheme } = useThemeMode()

    const showNavbar = !!user
    const { t } = useTranslation()

    const {
        token: { colorBgContainer, colorBorderSecondary },
    } = theme.useToken()

    // Determine active tab for mobile
    const getActiveTab = () => {
        if (path === '/' || path === '/search') return 'search'
        if (path.includes('/dashboard') || path.includes('/appointments')) return 'home'
        if (path.includes('/schedule')) return 'schedule'
        if (path.includes('/notifications')) return 'notifications'
        if (path.includes('/profile') || path.includes('/settings')) return 'profile'
        return 'home'
    }

    const handleTabChange = (key: string) => {
        switch (key) {
            case 'home':
                router.visit(isDoctor ? '/dashboard/doctor' : '/dashboard')
                break
            case 'search':
                router.visit('/search')
                break
            case 'schedule':
                router.visit(isDoctor ? '/doctor/schedule' : '/dashboard')
                break
            case 'notifications':
                router.visit('/notifications')
                break
            case 'profile':
                router.visit(isDoctor ? '/dashboard/doctor/profile' : '/dashboard/patient/profile')
                break
        }
    }

    // ==========================================================================
    // MOBILE LAYOUT
    // ==========================================================================
    if (isMobile) {
        const doctorTabs = [
            { key: 'home', title: 'Home', icon: <AppOutline /> },
            { key: 'schedule', title: 'Schedule', icon: <CalendarOutline /> },
            { key: 'search', title: 'Search', icon: <SearchOutline /> },
            { key: 'notifications', title: 'Alerts', icon: unreadCount > 0 ? <Badge count={unreadCount} size="small"><BellOutline /></Badge> : <BellOutline /> },
            { key: 'profile', title: 'Profile', icon: <UserOutline /> }
        ]

        const patientTabs = [
            { key: 'home', title: 'Home', icon: <AppOutline /> },
            { key: 'search', title: 'Search', icon: <SearchOutline /> },
            { key: 'notifications', title: 'Alerts', icon: unreadCount > 0 ? <Badge count={unreadCount} size="small"><BellOutline /></Badge> : <BellOutline /> },
            { key: 'profile', title: 'Profile', icon: <UserOutline /> }
        ]

        const guestTabs = [
            { key: 'search', title: 'Search', icon: <SearchOutline /> },
            { key: 'profile', title: 'Sign In', icon: <UserOutline /> }
        ]

        const tabs = user ? (isDoctor ? doctorTabs : patientTabs) : guestTabs

        const handleGuestTabChange = (key: string) => {
            if (key === 'search') {
                router.visit('/search')
            } else if (key === 'profile') {
                router.visit('/login')
            }
        }

        return (
            <div style={{
                minHeight: '100vh',
                display: 'flex',
                flexDirection: 'column',
                backgroundColor: colorScheme === 'dark' ? '#141414' : '#f5f5f5'
            }}>
                {/* Mobile Header */}
                <NavBar
                    back={null}
                    style={{
                        '--height': '52px',
                        '--border-bottom': `1px solid ${colorScheme === 'dark' ? '#303030' : '#f0f0f0'}`,
                        backgroundColor: colorScheme === 'dark' ? '#1f1f1f' : '#fff',
                        position: 'sticky',
                        top: 0,
                        zIndex: 100
                    }}
                    left={
                        <Link href="/" style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                            <img
                                src="/images/logo-medic-sun.svg"
                                alt="Medic"
                                style={{ height: 28, width: 'auto', filter: colorScheme === 'dark' ? 'brightness(0) invert(1)' : undefined }}
                            />
                            <Badge count="Beta" color="blue" size="small" />
                        </Link>
                    }
                    right={
                        <Space>
                            <Button
                                type="text"
                                shape="circle"
                                size="small"
                                icon={colorScheme === 'dark' ? <IconSun size={18} /> : <IconMoon size={18} />}
                                onClick={toggleColorScheme}
                            />
                            {user && (
                                <Avatar
                                    src={user.profileImageUrl}
                                    size="small"
                                    style={{ backgroundColor: '#0D9488' }}
                                    onClick={() => setMobileMenuOpen(true)}
                                >
                                    {user.firstName?.[0]}
                                </Avatar>
                            )}
                        </Space>
                    }
                />

                {/* Content Area */}
                <div style={{ flex: 1, overflow: 'auto', paddingBottom: showNavbar ? 60 : 0 }}>
                    {children}
                </div>

                {/* Bottom TabBar */}
                {showNavbar ? (
                    <div
                        style={{
                            position: 'fixed',
                            bottom: 0,
                            left: 0,
                            right: 0,
                            backgroundColor: colorScheme === 'dark' ? '#1f1f1f' : '#fff',
                            borderTop: `1px solid ${colorScheme === 'dark' ? '#303030' : '#f0f0f0'}`,
                            zIndex: 100,
                            paddingBottom: 'env(safe-area-inset-bottom)'
                        }}
                    >
                        <TabBar
                            activeKey={getActiveTab()}
                            onChange={handleTabChange}
                            style={{
                                '--adm-color-primary': '#0d9488'
                            }}
                        >
                            {tabs.map(tab => (
                                <TabBar.Item key={tab.key} icon={tab.icon} title={tab.title} />
                            ))}
                        </TabBar>
                    </div>
                ) : (
                    <div
                        style={{
                            position: 'fixed',
                            bottom: 0,
                            left: 0,
                            right: 0,
                            backgroundColor: colorScheme === 'dark' ? '#1f1f1f' : '#fff',
                            borderTop: `1px solid ${colorScheme === 'dark' ? '#303030' : '#f0f0f0'}`,
                            zIndex: 100,
                            paddingBottom: 'env(safe-area-inset-bottom)'
                        }}
                    >
                        <TabBar
                            activeKey={getActiveTab()}
                            onChange={handleGuestTabChange}
                            style={{
                                '--adm-color-primary': '#0d9488'
                            }}
                        >
                            {guestTabs.map(tab => (
                                <TabBar.Item key={tab.key} icon={tab.icon} title={tab.title} />
                            ))}
                        </TabBar>
                    </div>
                )}

                {/* User Menu Popup */}
                <Popup
                    visible={mobileMenuOpen}
                    onMaskClick={() => setMobileMenuOpen(false)}
                    position="bottom"
                    bodyStyle={{
                        borderTopLeftRadius: 16,
                        borderTopRightRadius: 16,
                        paddingBottom: 'env(safe-area-inset-bottom)'
                    }}
                >
                    <div style={{ padding: 20 }}>
                        {user && (
                            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20, paddingBottom: 16, borderBottom: '1px solid #f0f0f0' }}>
                                <Avatar src={user.profileImageUrl} size={48} style={{ backgroundColor: '#0D9488' }}>
                                    {user.firstName?.[0]}
                                </Avatar>
                                <div>
                                    <div style={{ fontWeight: 600, fontSize: 16 }}>{user.firstName} {user.lastName}</div>
                                    <div style={{ color: '#666', fontSize: 13 }}>{user.email}</div>
                                </div>
                            </div>
                        )}
                        <List>
                            <List.Item
                                prefix={<SetOutline />}
                                onClick={() => {
                                    setMobileMenuOpen(false)
                                    router.visit('/settings')
                                }}
                            >
                                Settings
                            </List.Item>
                            <List.Item
                                prefix={<IconLogout size={20} />}
                                onClick={() => {
                                    setMobileMenuOpen(false)
                                    router.delete('/logout')
                                }}
                                style={{ color: '#ff4d4f' }}
                            >
                                Logout
                            </List.Item>
                        </List>
                    </div>
                </Popup>
            </div>
        )
    }

    // ==========================================================================
    // DESKTOP LAYOUT (Original)
    // ==========================================================================

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
                    type={path === '/search' ? 'text' : 'text'}
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
