import { Badge, Button, Card, Group, SimpleGrid, Stack, Text, Title } from '@mantine/core'
import type { ReactElement } from 'react'
import { useTranslation } from 'react-i18next'

import type { AppPageProps } from '@/types/app'
import { PublicLayout } from '@/layouts/PublicLayout'

const heroStats = [
  { label: 'hero.doctors', fallback: 'Verified doctors', value: '600+' },
  { label: 'hero.appointments', fallback: 'Appointments booked', value: '10K+' },
  { label: 'hero.rating', fallback: 'Average rating', value: '4.8/5' }
]

const specialties = [
  { key: 'cardiology', label: 'Cardiology' },
  { key: 'orthopedics', label: 'Orthopedics' },
  { key: 'pediatrics', label: 'Pediatrics' },
  { key: 'dermatology', label: 'Dermatology' }
]

type PageProps = AppPageProps

const HomePage = ({ app, auth }: PageProps) => {
  const { t } = useTranslation('default')

  return (
    <Stack gap="xl">
      <Stack gap="md" align="flex-start">
        <Badge color="teal" size="lg" radius="sm">
          {t('home.badge', 'World-class care, on demand')}
        </Badge>
        <Title order={1} fw={800} c="dark">
          {t('home.hero.title', 'Find the right doctor for you')}
        </Title>
        <Text size="lg" c="dimmed">
          {t(
            'home.hero.subtitle',
            'Book trusted clinicians, manage visits, and access telemedicine in one beautiful experience.'
          )}
        </Text>
        <Group gap="md">
          <Button component="a" href="/search" size="lg">
            {t('home.cta.search', 'Search doctors')}
          </Button>
          <Button component="a" href="/register" variant="light" size="lg">
            {t('home.cta.register', 'Create account')}
          </Button>
        </Group>
      </Stack>

      <SimpleGrid cols={{ base: 1, sm: 2, lg: 3 }} spacing="lg">
        {heroStats.map((stat) => (
          <Card key={stat.label} shadow="sm" padding="lg" radius="md">
            <Text size="xs" c="dimmed" tt="uppercase">
              {t(stat.label, stat.fallback)}
            </Text>
            <Text size="40" fw={700} lh={1.1} mt="sm">
              {stat.value}
            </Text>
          </Card>
        ))}
      </SimpleGrid>

      <Stack gap="md">
        <Group justify="space-between">
          <Title order={2}>{t('home.specialties.title', 'Popular specialties')}</Title>
          <Button component="a" href="/search" variant="subtle">
            {t('home.specialties.cta', 'Browse all')}
          </Button>
        </Group>
        <SimpleGrid cols={{ base: 2, sm: 4 }} spacing="lg">
          {specialties.map((specialty) => (
            <Card key={specialty.key} shadow="xs" padding="lg" radius="lg" withBorder>
              <Text fw={600}>{t(`specialties.${specialty.key}`, specialty.label)}</Text>
            </Card>
          ))}
        </SimpleGrid>
      </Stack>
    </Stack>
  )
}

HomePage.layout = (page: ReactElement<PageProps>) => (
  <PublicLayout app={page.props.app} auth={page.props.auth}>
    {page}
  </PublicLayout>
)

export default HomePage
