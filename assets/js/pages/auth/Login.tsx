import {
    Anchor,
    Button,
    Card,
    Checkbox,
    Container,
    Group,
    PasswordInput,
    Stack,
    Text,
    TextInput,
    Title
} from '@mantine/core'
import { Link, useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

export default function LoginPage() {
    const { data, setData, post, processing, errors } = useForm({
        email: '',
        password: '',
        remember_me: false
    })

    const submit = (e: FormEvent) => {
        e.preventDefault()
        post('/login')
    }

    return (
        <Container size="xs" py={80}>
            <Stack align="center" mb="xl">
                <Title order={1}>Welcome back</Title>
                <Text c="dimmed">Sign in to manage your appointments</Text>
            </Stack>

            <Card withBorder shadow="md" p={30} radius="md">
                <form onSubmit={submit}>
                    <Stack gap="md">
                        <TextInput
                            label="Email address"
                            placeholder="you@medic.com"
                            required
                            value={data.email}
                            onChange={(e) => setData('email', e.target.value)}
                            error={errors.email}
                        />

                        <PasswordInput
                            label="Password"
                            placeholder="Your password"
                            required
                            value={data.password}
                            onChange={(e) => setData('password', e.target.value)}
                            error={errors.password}
                        />

                        <Group justify="space-between" mt="lg">
                            <Checkbox
                                label="Remember me"
                                checked={data.remember_me}
                                onChange={(e) => setData('remember_me', e.currentTarget.checked)}
                            />
                            <Anchor component={Link} href="/forgot-password" size="sm">
                                Forgot password?
                            </Anchor>
                        </Group>

                        <Button fullWidth mt="xl" type="submit" loading={processing}>
                            Sign in
                        </Button>
                    </Stack>
                </form>
            </Card>

            <Text ta="center" mt="md">
                Don&apos;t have an account?{' '}
                <Anchor component={Link} href="/register" fw={700}>
                    Register
                </Anchor>
            </Text>
        </Container>
    )
}
