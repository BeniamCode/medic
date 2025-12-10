import {
    Anchor,
    Button,
    Card,
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

export default function RegisterPage() {
    const { data, setData, post, processing, errors } = useForm({
        email: '',
        password: '',
        first_name: '',
        last_name: ''
    })

    const submit = (e: FormEvent) => {
        e.preventDefault()
        post('/register')
    }

    return (
        <Container size="xs" py={80}>
            <Stack align="center" mb="xl">
                <Title order={1}>Create an account</Title>
                <Text c="dimmed">Book appointments and manage your health</Text>
            </Stack>

            <Card withBorder shadow="md" p={30} radius="md">
                <form onSubmit={submit}>
                    <Stack gap="md">
                        <Group grow>
                            <TextInput
                                label="First name"
                                placeholder="John"
                                required
                                value={data.first_name}
                                onChange={(e) => setData('first_name', e.target.value)}
                                error={errors.first_name}
                            />
                            <TextInput
                                label="Last name"
                                placeholder="Doe"
                                required
                                value={data.last_name}
                                onChange={(e) => setData('last_name', e.target.value)}
                                error={errors.last_name}
                            />
                        </Group>

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
                            placeholder="Min. 8 characters"
                            required
                            value={data.password}
                            onChange={(e) => setData('password', e.target.value)}
                            error={errors.password}
                        />

                        <Button fullWidth mt="xl" type="submit" loading={processing}>
                            Create Patient Account
                        </Button>
                    </Stack>
                </form>
            </Card>

            <Text ta="center" mt="md">
                Are you a doctor?{' '}
                <Anchor component={Link} href="/register/doctor" fw={700}>
                    Register as a Specialist
                </Anchor>
            </Text>

            <Text ta="center" mt="xs">
                Already have an account?{' '}
                <Anchor component={Link} href="/login" fw={700}>
                    Sign in
                </Anchor>
            </Text>
        </Container>
    )
}
