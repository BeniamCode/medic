import { ActionIcon, AppShell, Avatar, Burger, Button, Container, Group, Image, Menu, Text, ThemeIcon, UnstyledButton } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
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
    IconUser,
    IconUserCircle
} from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import { SharedAppProps } from '@/types/app'

interface AppLayoutProps {
    children: React.ReactNode
}

export default function AppLayout({ children }: AppLayoutProps) {
    const [opened, { toggle }] = useDisclosure()
    const { auth, app } = usePage<SharedAppProps>().props
    const { url } = usePage()
    const path = url.split('?')[0]

    const isPublic = [
        '/',
        '/login',
        '/register',
        '/forgot-password'
    ].includes(path) || path.startsWith('/search') || path.startsWith('/doctors')

    const showNavbar = !isPublic

    const { t } = useTranslation()

    const user = auth.user
    const isDoctor = user?.role === 'doctor'

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
                        <Burger opened={opened} onClick={toggle} hiddenFrom="sm" size="sm" />
                        <Link href="/" className="flex items-center gap-2 no-underline text-inherit">
                            {/* Replace with actual logo path or component */}
                            <Text fw={900} size="xl" variant="gradient" gradient={{ from: 'teal', to: 'blue', deg: 45 }}>
                                MEDIC
                            </Text>
                        </Link>
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
                                                <Avatar src={user.profile_image_url} radius="xl" color="teal">
                                                    {user.first_name?.[0]}
                                                </Avatar>
                                                <div style={{ flex: 1 }} className="hidden sm:block">
                                                    <Text size="sm" fw={500}>{user.first_name} {user.last_name}</Text>
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
                        {/* Sidebar branding if needed */}
                    </Group>

                    <div className="flex flex-col gap-2">
                        <Button
                            variant="subtle"
                            justify="start"
                            size="md"
                            leftSection={<IconHome size={20} />}
                            component={Link}
                            href="/"
                        >
                            Home
                        </Button>

                        <Button
                            variant="subtle"
                            justify="start"
                            size="md"
                            leftSection={<IconSearch size={20} />}
                            component={Link}
                            href="/search"
                        >
                            Find Doctors
                        </Button>

                        {user && (
                            <>
                                <Text size="xs" fw={700} c="dimmed" mt="md" mb="xs" style={{ textTransform: 'uppercase' }}>
                                    {isDoctor ? 'Doctor' : 'Patient'}
                                </Text>

                                {isDoctor ? (
                                    <>
                                        <Button variant="subtle" justify="start" leftSection={<IconCalendar size={20} />} component={Link} href="/dashboard/doctor">
                                            Dashboard
                                        </Button>
                                        <Button variant="subtle" justify="start" leftSection={<IconCalendarEvent size={20} />} component={Link} href="/doctor/schedule">
                                            Schedule
                                        </Button>
                                        <Button variant="subtle" justify="start" leftSection={<IconUserCircle size={20} />} component={Link} href="/dashboard/doctor/profile">
                                            Profile
                                        </Button>
                                    </>
                                ) : (
                                    <Button variant="subtle" justify="start" leftSection={<IconCalendar size={20} />} component={Link} href="/dashboard">
                                        Appointments
                                    </Button>
                                )}
                            </>
                        )}
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
