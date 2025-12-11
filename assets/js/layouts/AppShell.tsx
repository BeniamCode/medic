import { ActionIcon, AppShell, Avatar, Badge, Burger, Button, Container, Group, Image, Menu, Text, ThemeIcon, UnstyledButton } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { Link, usePage } from '@inertiajs/react'
import { notifications } from '@mantine/notifications'
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
    IconUser,
    IconUserCircle
} from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import { SharedAppProps } from '@/types/app'
import { useEffect } from 'react'

interface AppLayoutProps {
    children: React.ReactNode
}

export default function AppLayout({ children }: AppLayoutProps) {
    const [opened, { toggle }] = useDisclosure()
    const { auth, app, flash } = usePage<SharedAppProps>().props
    const { url } = usePage()
    const path = url.split('?')[0]

    // Flash Message Handling
    useEffect(() => {
        if (flash.success) {
            notifications.show({
                title: 'Success',
                message: flash.success,
                color: 'teal',
                icon: <IconHome size={16} />, // Generic success icon or Check
            })
        }
        if (flash.error) {
            notifications.show({
                title: 'Error',
                message: flash.error,
                color: 'red',
            })
        }
        if (flash.info) {
            notifications.show({
                title: 'Info',
                message: flash.info,
                color: 'blue',
            })
        }
    }, [flash])


    const user = auth.user
    const isDoctor = user?.role === 'doctor'

    // Show Navbar if user is logged in, OR if specifically on dashboard pages (fallback)
    // User requested "logged in users ... need a left side panel", so we enforce it for authenticated users.
    const showNavbar = !!user

    const { t } = useTranslation()

    return (
        <AppShell
            header={{ height: 60 }}
            navbar={showNavbar ? {
                width: 300,
                breakpoint: 'sm',
                collapsed: { mobile: !opened }
            } : undefined}
            padding="md"
        >
            <AppShell.Header>
                <Group h="100%" px="md" justify="space-between">
                    <Group>
                        {showNavbar && <Burger opened={opened} onClick={toggle} hiddenFrom="sm" size="sm" />}
                        <Group>
                            <Link href="/">
                                <Image src="/images/medic-logo.svg" h={30} w="auto" alt="Medic Logo" />
                            </Link>
                            <Badge variant="light" color="blue">Beta</Badge>
                        </Group>
                    </Group>

                    <Group>
                        {user ? (
                            <Group gap="xs">
                                <ActionIcon variant="light" size="lg" radius="xl">
                                    <IconBell size={20} />
                                </ActionIcon>

                                <Menu shadow="md" width={200}>
                                    <Menu.Target>
                                        <UnstyledButton>
                                            <Group gap={8}>
                                                <Avatar src={user.profileImageUrl} radius="xl" color="teal">
                                                    {user.firstName?.[0]}
                                                </Avatar>
                                                <div style={{ flex: 1 }} className="hidden sm:block">
                                                    <Text size="sm" fw={500}>{user.firstName} {user.lastName}</Text>
                                                    <Text c="dimmed" size="xs">{user.email}</Text>
                                                </div>
                                            </Group>
                                        </UnstyledButton>
                                    </Menu.Target>

                                    <Menu.Dropdown>
                                        <Menu.Label>Application</Menu.Label>
                                        <Menu.Item leftSection={<IconSettings size={14} />} component={Link} href="/settings">
                                            Settings
                                        </Menu.Item>
                                        <Menu.Divider />
                                        <Menu.Item
                                            leftSection={<IconLogout size={14} />}
                                            color="red"
                                            component={Link}
                                            href="/logout"
                                            method="delete"
                                            as="button"
                                        >
                                            Logout
                                        </Menu.Item>
                                    </Menu.Dropdown>
                                </Menu>
                            </Group>
                        ) : (
                            <Group gap="xs">
                                <Button variant="subtle" component={Link} href="/login">Sign in</Button>
                                <Button component={Link} href="/register">Sign up</Button>
                            </Group>
                        )}
                    </Group>
                </Group>
            </AppShell.Header>

            {showNavbar && (
                <AppShell.Navbar p="md">
                    <Group mb="xl">
                        {/* Optional Branding here if not in header */}
                    </Group>

                    <div className="flex flex-col gap-2">
                        {/* Common Links */}
                        <Button
                            variant={path === '/' ? 'light' : 'subtle'}
                            justify="start"
                            size="md"
                            leftSection={<IconHome size={20} />}
                            component={Link}
                            href="/"
                            color="gray"
                        >
                            Home
                        </Button>

                        {isDoctor ? (
                            <>
                                <Text size="xs" fw={700} c="dimmed" mt="md" mb="xs" tt="uppercase">Practice</Text>
                                <Button
                                    variant={path.startsWith('/dashboard/doctor') && !path.includes('profile') ? 'light' : 'subtle'}
                                    justify="start"
                                    leftSection={<IconHome size={20} />}
                                    component={Link}
                                    href="/dashboard/doctor"
                                    color="teal"
                                >
                                    Dashboard
                                </Button>
                                <Button
                                    variant={path.startsWith('/doctor/schedule') ? 'light' : 'subtle'}
                                    justify="start"
                                    leftSection={<IconCalendarEvent size={20} />}
                                    component={Link}
                                    href="/doctor/schedule"
                                    color="teal"
                                >
                                    My Schedule
                                </Button>
                                <Button
                                    variant={path.includes('/doctor/profile') ? 'light' : 'subtle'}
                                    justify="start"
                                    leftSection={<IconUserCircle size={20} />}
                                    component={Link}
                                    href="/dashboard/doctor/profile"
                                    color="teal"
                                >
                                    My Profile
                                </Button>
                            </>
                        ) : (
                            <>
                                <Text size="xs" fw={700} c="dimmed" mt="md" mb="xs" tt="uppercase">Patient</Text>
                                <Button
                                    variant={path === '/dashboard' ? 'light' : 'subtle'}
                                    justify="start"
                                    leftSection={<IconCalendar size={20} />}
                                    component={Link}
                                    href="/dashboard"
                                    color="teal"
                                >
                                    Appointments
                                </Button>
                            </>
                        )}

                        <Text size="xs" fw={700} c="dimmed" mt="md" mb="xs" tt="uppercase">Discover</Text>
                        <Button
                            variant={path === '/search' ? 'light' : 'subtle'}
                            justify="start"
                            size="md"
                            leftSection={<IconSearch size={20} />}
                            component={Link}
                            href="/search"
                            color="gray"
                        >
                            Find Doctors
                        </Button>
                    </div>
                </AppShell.Navbar>
            )}

            <AppShell.Main>
                <Container size="xl" p={0}>
                    {children}
                </Container>
            </AppShell.Main>
        </AppShell>
    )
}
