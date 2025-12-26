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
    IconLayoutDashboard,
    IconLogout,
    IconMoon,
    IconSearch,
    IconSettings,
    IconSun,
    IconUserCircle,
    IconMenu2,
    IconUsers
} from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import { SharedAppProps } from '@/types/app'
import { useEffect, useState } from 'react'
import { useThemeMode } from '@/app'
import { ensureNotificationsStream } from '@/lib/notificationsStream'
import { useIsMobile } from '@/lib/device'
import { NotificationBell } from '@/components/NotificationBell'
import { LanguageSwitcher } from '@/components/LanguageSwitcher'

//Mobile antd-mobile imports
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
    const [collapsed, setCollapsed] = useState(false)
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false)
    const { auth, app, flash } = usePage<SharedAppProps>().props
    const { url } = usePage()
    const path = url.split('?')[0]

    const { notification } = AntdApp.useApp()

    const [unreadCount, setUnreadCount] = useState<number>(app.unread_count || 0)

    useEffect(() => {
        setUnreadCount(app.unread_count || 0)
    }, [app.unread_count])

    useEffect(() => {
        if (!auth.authenticated) {
            ensureNotificationsStream().stop()
            setUnreadCount(0)
            return
        }

        // Initialize notification stream
        if (!user) {
            ensureNotificationsStream().stop()
            return
        }

        ensureNotificationsStream().start()

        const updateUnreadCount = (ev: Event) => {
            const count = (ev as CustomEvent).detail?.count
            if (typeof count === 'number') {
                setUnreadCount(count)
            }
        }

        const onNewNotification = () => {
            // Invalidate the unread count or fetch recent
            // We rely on the stream to update us or we can fetch manually
            // For now, we just ensure the bell knows something happened
            window.dispatchEvent(new CustomEvent('medic:notifications:fetch_unread'))
        }

        window.addEventListener('medic:notifications:unreadCount', updateUnreadCount)
        window.addEventListener('medic:notifications:new', onNewNotification)

        return () => {
            window.removeEventListener('medic:notifications:unreadCount', updateUnreadCount)
            window.removeEventListener('medic:notifications:new', onNewNotification)
            ensureNotificationsStream().stop()
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
            { key: 'home', title: t('Home'), icon: <AppOutline /> },
            { key: 'schedule', title: t('Schedule'), icon: <CalendarOutline /> },
            { key: 'search', title: t('Search'), icon: <SearchOutline /> },
            { key: 'notifications', title: t('Alerts'), icon: unreadCount > 0 ? <Badge count={unreadCount} size="small"><BellOutline /></Badge> : <BellOutline /> },
            { key: 'profile', title: t('Profile'), icon: <UserOutline /> }
        ]

        const patientTabs = [
            { key: 'home', title: t('Home'), icon: <AppOutline /> },
            { key: 'search', title: t('Search'), icon: <SearchOutline /> },
            { key: 'notifications', title: t('Alerts'), icon: unreadCount > 0 ? <Badge count={unreadCount} size="small"><BellOutline /></Badge> : <BellOutline /> },
            { key: 'profile', title: t('Profile'), icon: <UserOutline /> }
        ]

        const guestTabs = [
            { key: 'search', title: t('Search'), icon: <SearchOutline /> },
            { key: 'profile', title: t('Sign In'), icon: <UserOutline /> }
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
                            <span style={{ fontFamily: 'DM Sans, sans-serif', fontWeight: 700, fontSize: 20, color: colorScheme === 'dark' ? '#fff' : '#000', lineHeight: 1 }}>medic</span>
                            <Badge count="Beta" color="blue" size="small" style={{ marginLeft: 4 }} />
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
                                {t('Settings')}
                            </List.Item>
                            <List.Item
                                prefix={<IconLogout size={20} />}
                                onClick={() => {
                                    setMobileMenuOpen(false)
                                    const token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''
                                    router.delete('/logout', { headers: { 'X-CSRF-Token': token } })
                                }}
                                style={{ color: '#ff4d4f' }}
                            >
                                {t('Logout')}
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
                label: <Link href="/settings">{t('Settings')}</Link>,
                icon: <IconSettings size={14} />
            },
            {
                type: 'divider'
            },
            {
                key: 'logout',
                label: (
                    <span
                        onClick={() => {
                            const token = document.querySelector("meta[name='csrf-token']")?.getAttribute('content') || ''
                            router.delete('/logout', { headers: { 'X-CSRF-Token': token } })
                        }}
                        className="w-full text-left cursor-pointer"
                    >
                        {t('Logout')}
                    </span>
                ),
                icon: <IconLogout size={14} />,
                danger: true
            }
        ]
    }

    const NavContent = ({ collapsed = false }: { collapsed?: boolean }) => (
        <Flex vertical gap="small" className="h-full">
            <Link href="/">
                <Button
                    type={path === '/' ? 'primary' : 'text'}
                    ghost={path === '/'}
                    className={path === '/' ? 'bg-teal-50 text-teal-700' : ''}
                    block
                    style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                    icon={<IconHome size={20} />}
                >
                    {!collapsed && t('Home')}
                </Button>
            </Link>

            {isDoctor ? (
                <>
                    {!collapsed && <Text type="secondary" style={{ fontSize: '11px', fontWeight: 700, marginTop: 16, marginBottom: 8, textTransform: 'uppercase' }}>{t('Practice')}</Text>}
                    <Link href="/dashboard/doctor">
                        <Button
                            type={path.startsWith('/dashboard/doctor') && !path.includes('profile') ? 'primary' : 'text'}
                            ghost={path.startsWith('/dashboard/doctor') && !path.includes('profile')}
                            className={path.startsWith('/dashboard/doctor') && !path.includes('profile') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconLayoutDashboard size={20} />}
                        >
                            {!collapsed && t('Dashboard')}
                        </Button>
                    </Link>
                    <Link href="/dashboard/doctor?tab=patients">
                        <Button
                            type={url.includes('tab=patients') ? 'primary' : 'text'}
                            ghost={url.includes('tab=patients')}
                            className={url.includes('tab=patients') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconUsers size={20} />}
                        >
                            {!collapsed && t('My Patients')}
                        </Button>
                    </Link>
                    <Link href="/dashboard/doctor/appointments">
                        <Button
                            type={path.startsWith('/dashboard/doctor/appointments') ? 'primary' : 'text'}
                            ghost={path.startsWith('/dashboard/doctor/appointments')}
                            className={path.startsWith('/dashboard/doctor/appointments') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconCalendarEvent size={20} />}
                        >
                            {!collapsed && t('Appointments')}
                        </Button>
                    </Link>
                    <Link href="/doctor/schedule">
                        <Button
                            type={path.startsWith('/doctor/schedule') ? 'primary' : 'text'}
                            ghost={path.startsWith('/doctor/schedule')}
                            className={path.startsWith('/doctor/schedule') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconCalendarEvent size={20} />}
                        >
                            {!collapsed && t('My Schedule')}
                        </Button>
                    </Link>
                    <Link href="/dashboard/doctor/calendar">
                        <Button
                            type={path.startsWith('/dashboard/doctor/calendar') ? 'primary' : 'text'}
                            ghost={path.startsWith('/dashboard/doctor/calendar')}
                            className={path.startsWith('/dashboard/doctor/calendar') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconCalendar size={20} />}
                        >
                            {!collapsed && t('Booking Calendar')}
                        </Button>
                    </Link>
                    <Link href="/dashboard/doctor/profile">
                        <Button
                            type={path.includes('/doctor/profile') ? 'primary' : 'text'}
                            ghost={path.includes('/doctor/profile')}
                            className={path.includes('/doctor/profile') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconUserCircle size={20} />}
                        >
                            {!collapsed && t('My Profile')}
                        </Button>
                    </Link>
                    <Link href="/notifications">
                        <Button
                            type={path.startsWith('/notifications') ? 'primary' : 'text'}
                            ghost={path.startsWith('/notifications')}
                            className={path.startsWith('/notifications') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconBell size={20} />}
                        >
                            {!collapsed && t('Notifications')}
                        </Button>
                    </Link>
                </>
            ) : (
                <>
                    {!collapsed && <Text type="secondary" style={{ fontSize: '11px', fontWeight: 700, marginTop: 16, marginBottom: 8, textTransform: 'uppercase' }}>{t('Patient')}</Text>}
                    <Link href="/dashboard">
                        <Button
                            type={path === '/dashboard' ? 'primary' : 'text'}
                            ghost={path === '/dashboard'}
                            className={path === '/dashboard' ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconCalendar size={20} />}
                        >
                            {!collapsed && t('Appointments')}
                        </Button>
                    </Link>

                    <Link href="/dashboard?tab=doctors">
                        <Button
                            type={url.includes('tab=doctors') ? 'primary' : 'text'}
                            ghost={url.includes('tab=doctors')}
                            className={url.includes('tab=doctors') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconUsers size={20} />}
                        >
                            {!collapsed && t('My Doctors')}
                        </Button>
                    </Link>

                    <Link href="/dashboard/patient/profile">
                        <Button
                            type={path.startsWith('/dashboard/patient/profile') ? 'primary' : 'text'}
                            ghost={path.startsWith('/dashboard/patient/profile')}
                            className={path.startsWith('/dashboard/patient/profile') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconUserCircle size={20} />}
                        >
                            {!collapsed && t('My Profile')}
                        </Button>
                    </Link>

                    <Link href="/notifications">
                        <Button
                            type={path.startsWith('/notifications') ? 'primary' : 'text'}
                            ghost={path.startsWith('/notifications')}
                            className={path.startsWith('/notifications') ? 'bg-teal-50 text-teal-700' : ''}
                            block
                            style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                            icon={<IconBell size={20} />}
                        >
                            {!collapsed && t('Notifications')}
                        </Button>
                    </Link>
                </>
            )
            }

            {!collapsed && <Text type="secondary" style={{ fontSize: '11px', fontWeight: 700, marginTop: 16, marginBottom: 8, textTransform: 'uppercase' }}>{t('Discover')}</Text>}
            <Link href="/search">
                <Button
                    type={path === '/search' ? 'text' : 'text'}
                    className={path === '/search' ? 'bg-gray-100' : ''}
                    block
                    style={{ justifyContent: collapsed ? 'center' : 'flex-start' }}
                    icon={<IconSearch size={20} />}
                >
                    {!collapsed && t('Find Doctors')}
                </Button>
            </Link>
        </Flex >
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
                            onClick={() => {
                                if (isMobile) {
                                    // On mobile, the drawer is still needed
                                } else {
                                    // On desktop, toggle sidebar
                                    setCollapsed(!collapsed)
                                }
                            }}
                        />
                    )}
                    <Link href="/" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                        <img
                            src="/images/logo-medic-sun.svg"
                            alt="Medic"
                            style={{ height: 32, width: 'auto', filter: colorScheme === 'dark' ? 'brightness(0) invert(1)' : undefined }}
                        />
                        <span style={{ fontFamily: 'DM Sans, sans-serif', fontWeight: 700, fontSize: 24, color: colorScheme === 'dark' ? '#fff' : '#000', lineHeight: 1 }}>medic</span>
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
                            <NotificationBell />
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
                                <Button type="text">{t('Sign In')}</Button>
                            </Link>
                            <Link href="/register">
                                <Button type="primary">{t('Sign Up')}</Button>
                            </Link>
                        </Space>
                    )}
                    <LanguageSwitcher />
                </Flex>
            </Header>

            <Layout>
                {showNavbar && (
                    <>
                        {/* Desktop Sidebar */}
                        <Sider
                            width={240}
                            theme="light"
                            breakpoint="md"
                            collapsed={collapsed}
                            collapsedWidth={64}
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
                                <NavContent collapsed={collapsed} />
                            </div>
                        </Sider>
                    </>
                )}

                <Content style={{ padding: 16, maxWidth: 1280, width: '100%', margin: '0 auto' }}>
                    {children}
                </Content>
            </Layout>
        </Layout>
    )
}
