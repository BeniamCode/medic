import { ActionIcon, Badge, Button, Card, Container, Grid, Group, SimpleGrid, Stack, Text, ThemeIcon, Title, rem } from '@mantine/core'
import { IconCalendar, IconDeviceLaptop, IconSearch, IconShieldCheck, IconStethoscope, IconUserCheck } from '@tabler/icons-react'
import { Link } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'
import { LoopAnimation } from '@/components/LoopAnimation'

const features = [
  {
    icon: IconSearch,
    title: 'Easy Search',
    description: 'Find specialists by name, specialty, or location instantly.'
  },
  {
    icon: IconCalendar,
    title: 'Instant Booking',
    description: 'Real-time availability means no more phone tag.'
  },
  {
    icon: IconUserCheck,
    title: 'Verified Doctors',
    description: 'Every specialist is vetted for license and quality.'
  },
  {
    icon: IconDeviceLaptop,
    title: 'Telemedicine',
    description: 'Connect with doctors from the comfort of your home.'
  }
]

export default function HomePage({ app, auth }: AppPageProps) {
  const { t } = useTranslation('default')

  return (
    <Stack gap={80} pb={80}>
      {/* Hero Section */}
      <Container size="xl">
        <Grid gutter={50} align="center">
          <Grid.Col span={{ base: 12, md: 6 }}>
            <Stack gap="xl">
              <Badge variant="light" size="lg" radius="xl" color="teal">
                New: Telemedicine Support
              </Badge>

              <Title order={1} style={{ fontSize: rem(52), lineHeight: 1.1 }}>
                Modern healthcare for <Text span c="teal" inherit>everyone</Text>
              </Title>

              <Text size="xl" c="dimmed">
                Book appointments with trusted doctors, manage your visits, and take control of your health journey—all in one place.
              </Text>

              <Group>
                <Button
                  component={Link}
                  href="/search"
                  size="xl"
                  radius="xl"
                  leftSection={<IconSearch size={20} />}
                >
                  Find a Doctor
                </Button>
                <Button
                  component={Link}
                  href="/register"
                  variant="default"
                  size="xl"
                  radius="xl"
                >
                  Join as Patient
                </Button>
              </Group>

              <Group mt="xl">
                <AvatarGroup count={500} />
                <Text size="sm" c="dimmed">
                  Trusted by 10,000+ patients
                </Text>
              </Group>
            </Stack>
          </Grid.Col>

          <Grid.Col span={{ base: 12, md: 6 }} visibleFrom="md">
            <Card radius={30} padding={0} h={400} withBorder style={{ overflow: 'hidden', background: 'linear-gradient(135deg, #042527, #0b4246)' }}>
              <LoopAnimation />
            </Card>
          </Grid.Col>
        </Grid>
      </Container>

      {/* Features Grid */}
      <Container size="xl" w="100%">
        <SimpleGrid cols={{ base: 1, sm: 2, md: 4 }} spacing="xl">
          {features.map((feature) => (
            <Card key={feature.title} shadow="sm" radius="lg" padding="xl" withBorder>
              <ThemeIcon size={48} radius="md" variant="light" color="teal" mb="lg">
                <feature.icon size={24} stroke={1.5} />
              </ThemeIcon>
              <Text fw={700} size="lg" mb="xs">{feature.title}</Text>
              <Text c="dimmed" size="sm" lh={1.6}>{feature.description}</Text>
            </Card>
          ))}
        </SimpleGrid>
      </Container>

      {/* CTA Section */}
      <Container size="md">
        <Card radius="xl" padding={60} bg="teal.9" c="white" withBorder={false}>
          <Stack align="center" gap="lg" style={{ textAlign: 'center' }}>
            <ThemeIcon size={60} radius="xl" bg="white" color="teal">
              <IconStethoscope size={30} />
            </ThemeIcon>
            <Title order={2} c="white">Are you a qualified doctor?</Title>
            <Text c="teal.1" maw={500}>
              Join our network of over 600 verified specialists. specific tools to manage your schedule and grow your practice.
            </Text>
            <Button
              component={Link}
              href="/register/doctor"
              size="lg"
              variant="white"
              c="teal"
              radius="xl"
            >
              Join Medic Network
            </Button>
          </Stack>
        </Card>
      </Container>
    </Stack>
  )
}

function AvatarGroup({ count }: { count: number }) {
  return (
    <Group gap={-10}>
      {[...Array(4)].map((_, i) => (
        <div key={i} style={{
          width: 32,
          height: 32,
          borderRadius: '50%',
          backgroundColor: `var(--mantine-color-gray-${i + 2})`,
          border: '2px solid white'
        }} />
      ))}
      <div style={{
        width: 32,
        height: 32,
        borderRadius: '50%',
        backgroundColor: 'var(--mantine-color-gray-1)',
        border: '2px solid white',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: 10,
        fontWeight: 700
      }}>
        {count}+
      </div>
    </Group>
  )
}
