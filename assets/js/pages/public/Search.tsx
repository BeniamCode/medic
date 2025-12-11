import { useMemo, useState, type FormEvent } from 'react'
import { Link, router } from '@inertiajs/react'
import {
  Badge,
  Box,
  Button,
  Card,
  Grid,
  Group,
  Image,
  Stack,
  Text,
  TextInput,
  Title,
  Select,
  RangeSlider,
  Paper,
  Divider,
  ThemeIcon,
  rem,
  Avatar,
  Rating
} from '@mantine/core'
import { IconFilter, IconMapPin, IconSearch, IconStar, IconStethoscope } from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'

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

const createParams = (query: string, specialty: string) => {
  const params = new URLSearchParams()
  if (query) params.set('q', query)
  if (specialty) params.set('specialty', specialty)
  return params
}

export default function SearchPage({ app, auth, doctors = [], specialties = [], filters = { query: '', specialty: '' }, meta }: SearchProps) {
  const { t } = useTranslation('default')
  const [query, setQuery] = useState(filters?.query || '')
  const [specialty, setSpecialty] = useState(filters?.specialty ?? '')

  // Debug Log
  console.log('Search Render:', { doctors, specialties, filters })

  const specialtyOptions = useMemo(
    () =>
      specialties.map((item: { name: string; slug: string }) => ({
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
    <Box>
      <Box bg="teal.0" py={40} mb={40} style={{ borderBottom: `1px solid var(--mantine-color-teal-1)` }}>
        <Grid gutter="xl" align="flex-end">
          <Grid.Col span={{ base: 12, md: 8 }}>
            <Title order={1} mb="xs">{t('search.title', 'Find your specialist')}</Title>
            <Text c="dimmed" size="lg">{t('search.subtitle', 'Browse verified doctors and clinics nearby')}</Text>
          </Grid.Col>
        </Grid>
      </Box>

      <Grid gutter={40}>
        {/* Sidebar Filters */}
        <Grid.Col span={{ base: 12, md: 3 }}>
          <Stack gap="lg" style={{ position: 'sticky', top: 20 }}>
            <Paper shadow="sm" radius="lg" p="lg" withBorder>
              <Group mb="md">
                <ThemeIcon color="teal" variant="light"><IconFilter size={18} /></ThemeIcon>
                <Text fw={700}>Filters</Text>
              </Group>

              <form onSubmit={submit}>
                <Stack gap="md">
                  <TextInput
                    label={t('search.form.query', 'Keyword')}
                    placeholder="Name, symptom..."
                    leftSection={<IconSearch size={16} />}
                    value={query}
                    onChange={(event) => setQuery(event.currentTarget.value)}
                  />

                  <Select
                    label={t('search.form.specialty', 'Specialty')}
                    placeholder="Any specialty"
                    data={specialtyOptions}
                    value={specialty}
                    onChange={(value) => setSpecialty(value || '')}
                    clearable
                    searchable
                  />

                  {/* RangeSlider Removed for Debug */}
                  {/* Map Placeholder Removed for Debug */}

                  <Box p="xs" bg="red.1">
                    <Text size="xs" c="red">Debug: Filters Loaded. Query: {query}</Text>
                  </Box>

                  <Button type="submit" fullWidth mt="md">
                    {t('search.form.apply', 'Apply Filters')}
                  </Button>
                </Stack>
              </form>
            </Paper>
          </Stack>
        </Grid.Col>

        {/* Results */}
        <Grid.Col span={{ base: 12, md: 9 }}>
          <Group justify="space-between" mb="lg">
            <Text fw={600} size="lg"> {meta.total} specialists found</Text>
            <Badge color="gray" variant="light">Sort by: Best Match</Badge>
          </Group>

          <Stack gap="lg">
            {/* Debug Header */}
            <Text c="dimmed" size="xs">Debug: Doctors Count: {doctors?.length}</Text>

            {doctors.map((doctor: SearchDoctor) => (
              <Card key={doctor.id} shadow="sm" padding="lg" radius="lg" withBorder>
                <Grid>
                  <Grid.Col span={{ base: 12, sm: 3 }} style={{ display: 'flex', justifyContent: 'center' }}>
                    <Avatar
                      src={doctor.profile_image_url}
                      size={120}
                      radius="md"
                    >
                      {doctor.first_name?.charAt(0) || 'D'}
                    </Avatar>
                  </Grid.Col>

                  <Grid.Col span={{ base: 12, sm: 6 }}>
                    <Stack gap={4}>
                      <Group gap="xs">
                        <Title order={3} size="h4">{doctor.first_name} {doctor.last_name}</Title>
                        {doctor.verified && <Badge variant="dot" color="teal">Verified</Badge>}
                      </Group>

                      <Group gap={6} c="dimmed">
                        <IconStethoscope size={16} />
                        <Text size="sm">{doctor.specialty_name}</Text>
                      </Group>

                      <Group gap={6} c="dimmed">
                        <IconMapPin size={16} />
                        <Text size="sm">{doctor.city}</Text>
                      </Group>

                      <Group mt="sm">
                        <Rating value={doctor.rating || 0} readOnly size="sm" />
                        <Text size="sm" c="dimmed">({doctor.review_count} reviews)</Text>
                      </Group>
                    </Stack>
                  </Grid.Col>

                  <Grid.Col span={{ base: 12, sm: 3 }}>
                    <Stack h="100%" justify="center" gap="xs">
                      <Text ta="center" size="sm" c="dimmed">Consultation Fee</Text>
                      <Text ta="center" size="xl" fw={700} c="teal">
                        {doctor.consultation_fee ? `€${doctor.consultation_fee}` : 'Ask'}
                      </Text>
                      <Button component={Link} href={`/doctors/${doctor.id}`} variant="light" fullWidth mt="sm">
                        View Profile
                      </Button>
                      <Button component={Link} href={`/doctors/${doctor.id}?book=true`} fullWidth>
                        Book Now
                      </Button>
                    </Stack>
                  </Grid.Col>
                </Grid>
              </Card>
            ))}

            {doctors.length === 0 && (
              <Stack align="center" py={50}>
                <ThemeIcon size={60} radius="xl" color="gray" variant="light">
                  <IconSearch size={30} />
                </ThemeIcon>
                <Text size="xl" fw={600}>No doctors found</Text>
                <Text c="dimmed">Try adjusting your filters</Text>
              </Stack>
            )}
          </Stack>
        </Grid.Col>
      </Grid>
    </Box>
  )
}
