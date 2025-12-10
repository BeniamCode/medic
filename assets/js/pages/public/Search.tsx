import { useMemo, useState, type FormEvent } from 'react'
import { router } from '@inertiajs/react'
import {
  Badge,
  Box,
  Button,
  Card,
  Group,
  Image,
  SimpleGrid,
  Stack,
  Text,
  TextInput,
  Title,
  Select
} from '@mantine/core'
import { IconMapPin, IconStar } from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'

import type { AppPageProps } from '@/types/app'
import { PublicLayout } from '@/layouts/PublicLayout'

export type SearchDoctor = {
  id: string
  first_name: string
  last_name: string
  specialty_name: string | null
  city: string | null
  rating: number | null
  review_count: number | null
  consultation_fee: number | null
  verified: boolean
  profile_image_url: string | null
}

type SearchProps = AppPageProps<{
  doctors: SearchDoctor[]
  specialties: { id: string; name: string; slug: string }[]
  filters: { query: string; specialty: string | null }
  meta: { total: number; source: string }
}>

const cardPlaceholder = 'https://images.unsplash.com/photo-1527613426441-4da17471b66d?auto=format&fit=crop&w=400&q=80'

const createParams = (query: string, specialty: string) => {
  const params = new URLSearchParams()
  if (query) params.set('q', query)
  if (specialty) params.set('specialty', specialty)
  return params
}

const SearchPage = ({ app, auth, doctors, specialties, filters, meta }: SearchProps) => {
  const { t } = useTranslation('default')
  const [query, setQuery] = useState(filters.query)
  const [specialty, setSpecialty] = useState(filters.specialty ?? '')

  const specialtyOptions = useMemo(
    () =>
      specialties.map((item) => ({
        value: item.slug,
        label: item.name
      })),
    [specialties]
  )

  const submit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault()
    router.get(`/search?${createParams(query, specialty).toString()}`, undefined, {
      preserveScroll: true,
      preserveState: true
    })
  }

  return (
    <PublicLayout app={app} auth={auth}>
      <Stack gap="xl">
        <Stack gap="sm">
          <Title order={1}>{t('search.title', 'Find your specialist')}</Title>
          <Text c="dimmed">{t('search.subtitle', 'Browse verified doctors and clinics')}</Text>
        </Stack>

        <Box component="form" onSubmit={submit} className="space-y-4">
          <SimpleGrid cols={{ base: 1, md: 3 }} spacing="md">
            <TextInput
              label={t('search.form.query', 'Name or symptom')}
              placeholder={t('search.form.placeholder', 'eg. cardiology, knee pain, Athens')}
              value={query}
              onChange={(event) => setQuery(event.currentTarget.value)}
              size="md"
            />
            <Select
              label={t('search.form.specialty', 'Specialty')}
              placeholder={t('search.form.specialty_placeholder', 'All specialties')}
              data={specialtyOptions}
              value={specialty}
              onChange={(value) => setSpecialty(value || '')}
              clearable
              size="md"
              searchable
            />
            <Group align="flex-end">
              <Button type="submit" size="md" fullWidth>
                {t('search.form.submit', 'Search')}
              </Button>
            </Group>
          </SimpleGrid>
        </Box>

        <Group justify="space-between" align="center">
          <Text c="dimmed">
            {t('search.results.count', { defaultValue: '{{count}} results', count: meta.total })}
          </Text>
          <Badge color="blue" variant="light">
            {meta.source === 'search'
              ? t('search.results.mode_search', 'Powered by instant search')
              : t('search.results.mode_catalog', 'Showing featured doctors')}
          </Badge>
        </Group>

        {doctors.length === 0 ? (
          <Card shadow="sm" padding="xl" radius="lg" withBorder>
            <Stack gap="xs" align="center">
              <Title order={4}>{t('search.empty.title', 'No matches yet')}</Title>
              <Text c="dimmed" ta="center">
                {t('search.empty.body', 'Try adjusting your filters or search for another symptom.')}
              </Text>
            </Stack>
          </Card>
        ) : (
          <SimpleGrid cols={{ base: 1, sm: 2, lg: 3 }} spacing="lg">
            {doctors.map((doctor) => (
              <Card key={doctor.id} shadow="md" padding="lg" radius="lg" withBorder>
                <Group gap="md" align="flex-start">
                  <Image
                    src={doctor.profile_image_url || cardPlaceholder}
                    radius="md"
                    width={72}
                    height={72}
                    alt={`${doctor.first_name} ${doctor.last_name}`}
                  />
                  <Stack gap={4} flex={1}>
                    <Group gap="xs">
                      <Title order={4} fz="lg">
                        {doctor.first_name} {doctor.last_name}
                      </Title>
                      {doctor.verified && <Badge color="teal">{t('search.card.verified', 'Verified')}</Badge>}
                    </Group>
                    <Text size="sm" c="dimmed">
                      {doctor.specialty_name || t('search.card.general', 'General practice')}
                    </Text>
                    <Group gap="xs" grow={false} wrap="nowrap">
                      <IconMapPin size={16} stroke={1.5} />
                      <Text size="sm">{doctor.city || t('search.card.anywhere', 'Anywhere')}</Text>
                    </Group>
                    <Group gap="sm">
                      <Group gap={4} wrap="nowrap" align="center">
                        <IconStar size={16} stroke={1.5} className="text-yellow-500" />
                        <Text size="sm" fw={600}>
                          {doctor.rating ? doctor.rating.toFixed(1) : '—'}
                        </Text>
                        <Text size="xs" c="dimmed">
                          ({doctor.review_count || 0})
                        </Text>
                      </Group>
                      {doctor.consultation_fee && (
                        <Text size="sm" fw={500}>
                          €{doctor.consultation_fee.toFixed(0)}
                        </Text>
                      )}
                    </Group>
                    <Button component="a" href={`/doctors/${doctor.id}`} variant="light">
                      {t('search.card.view_profile', 'View profile')}
                    </Button>
                  </Stack>
                </Group>
              </Card>
            ))}
          </SimpleGrid>
        )}
      </Stack>
    </PublicLayout>
  )
}

export default SearchPage
