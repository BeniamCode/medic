import { useMemo, useState, useEffect, useRef, type FormEvent } from 'react'
import { Link, router } from '@inertiajs/react'
import { useDebouncedValue } from '@mantine/hooks'
import {
  Badge,
  Box,
  Button,
  Card,
  Container,
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
  Rating,
  SimpleGrid
} from '@mantine/core'
import { IconFilter, IconMapPin, IconSearch, IconStar, IconStethoscope } from '@tabler/icons-react'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'

export type SearchDoctor = {
  id: string
  firstName: string
  lastName: string
  specialtyName: string | null
  city: string | null
  address: string | null
  rating: number | null
  reviewCount: number | null
  consultationFee: number | null
  verified: boolean
  profileImageUrl: string | null
  locationLat: number | null
  locationLng: number | null
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

import DoctorMap from '@/components/Map'

export default function SearchPage({ app, auth, doctors = [], specialties = [], filters = { query: '', specialty: '' }, meta }: SearchProps) {
  const { t } = useTranslation('default')

  // Initialize state
  const [query, setQuery] = useState(filters?.query || '')
  const [debouncedQuery] = useDebouncedValue(query, 300)
  const [specialty, setSpecialty] = useState(filters?.specialty ?? '')
  const [mapHeight, setMapHeight] = useState(250)

  const isMounted = useRef(false)

  // Live Search Effect
  useEffect(() => {
    // Skip the first render to avoid double fetching (since initial state matches props)
    if (!isMounted.current) {
      isMounted.current = true
      return
    }

    // Only fire if the debounced query is different from what's currently filtered (prevents loops if backend cleans string)
    // Actually, simple router.get is safer, Inertia handles duplicate visits efficiently.
    router.get(`/search?${createParams(debouncedQuery, specialty).toString()}`, undefined, {
      preserveScroll: true,
      preserveState: true,
      replace: true // Replace history state for typing updates to avoid massive back-button history
    })
  }, [debouncedQuery, specialty])

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
    // Instant trigger (ignores debounce)
    router.get(`/search?${createParams(query, specialty).toString()}`, undefined, {
      preserveScroll: true,
      preserveState: true
    })
  }

  return (
    <Box>
      {/* 1. Map Container - Top */}
      <Paper
        h={mapHeight}
        w="100%"
        bg="gray.1"
        style={{
          transition: 'height 0.3s ease',
          zIndex: 10,
          position: 'relative',
          overflow: 'hidden'
        }}
        onMouseEnter={() => setMapHeight(500)}
        onMouseLeave={() => setMapHeight(250)}
      >
        {/* Render Map at full 500px height always, so it just "reveals" instead of resizing */}
        <DoctorMap doctors={doctors} height={500} />
      </Paper>

      {/* 2. Google-Style Search Bar - Centered */}
      <Container size="md" mt={-30} style={{ position: 'relative', zIndex: 20 }}>
        <Paper shadow="xl" radius="xl" p="xs" withBorder>
          <form onSubmit={submit}>
            <TextInput
              placeholder={t('search.placeholder', 'Search doctors, clinics, specialties, etc.')}
              size="lg"
              variant="unstyled"
              radius="xl"
              pl="md"
              value={query}
              onChange={(event) => setQuery(event.currentTarget.value)}
              leftSection={<IconSearch size={22} color="var(--mantine-color-dimmed)" />}
              rightSection={
                <Button type="submit" radius="xl" size="sm" color="teal">
                  Search
                </Button>
              }
              rightSectionWidth={100}
            />
          </form>
        </Paper>
      </Container>


      <Container size="xl" mt={50} pb={50}>
        <Grid gutter={40}>
          {/* Sidebar Filters */}
          <Grid.Col span={{ base: 12, md: 3 }}>
            <Stack gap="lg" style={{ position: 'sticky', top: 20 }}>
              <Paper shadow="sm" radius="lg" p="lg" withBorder>
                <Group mb="md">
                  <ThemeIcon color="teal" variant="light"><IconFilter size={18} /></ThemeIcon>
                  <Text fw={700}>Filters</Text>
                </Group>

                <Stack gap="md">
                  <Select
                    label={t('search.form.specialty', 'Specialty')}
                    placeholder="Any specialty"
                    data={specialtyOptions}
                    value={specialty}
                    onChange={(value) => setSpecialty(value || '')}
                    clearable
                    searchable
                  />

                  {/* RangeSlider */}
                  <Box>
                    <Text size="sm" fw={500} mb="xs">Price Range</Text>
                    <RangeSlider
                      color="teal"
                      min={0} max={300}
                      step={10}
                      defaultValue={[0, 300]}
                      label={(val) => `€${val}`}
                    />
                  </Box>

                  <Button onClick={() => submit({ preventDefault: () => { } } as any)} fullWidth mt="md" variant="light">
                    {t('search.form.apply', 'Update Results')}
                  </Button>
                </Stack>
              </Paper>
            </Stack>
          </Grid.Col>

          {/* Results */}
          <Grid.Col span={{ base: 12, md: 9 }}>
            <Group justify="space-between" mb="lg">
              <Text fw={600} size="lg"> {meta.total} specialists found</Text>
              <Badge color="gray" variant="light">Sort by: Best Match</Badge>
            </Group>

            <SimpleGrid cols={{ base: 1, sm: 2, md: 3 }} spacing="lg">
              {doctors.map((doctor: SearchDoctor) => {
                return (
                  <Card key={doctor.id} shadow="sm" padding="lg" radius="lg" withBorder>
                    <Card.Section>
                      <Box h={200} bg="gray.1" style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                        <Avatar
                          src={doctor.profileImageUrl}
                          size={120}
                          radius="xl"
                        >
                          {doctor.firstName?.charAt(0) || 'D'}
                        </Avatar>
                      </Box>
                    </Card.Section>

                    <Stack mt="md" gap="xs">
                      <Group justify="space-between" align="start">
                        <Box>
                          <Title order={3} size="h4" lh={1.2}>
                            {doctor.firstName} {doctor.lastName}
                          </Title>
                          {doctor.verified && <Badge variant="dot" color="teal" size="xs" mt={4}>Verified</Badge>}
                        </Box>

                        <Rating value={doctor.rating || 0} readOnly size="xs" />
                      </Group>

                      <Text size="sm" c="dimmed" fw={500}>{doctor.specialtyName || 'General Practitioner'}</Text>

                      <Group gap={6} c="dimmed">
                        <IconMapPin size={16} />
                        <Text size="sm">{doctor.city || 'Online'}</Text>
                      </Group>

                      <Group justify="space-between" mt="md" align="center">
                        <Text fw={700} c="teal" size="lg">
                          {doctor.consultationFee ? `€${doctor.consultationFee}` : 'Ask'}
                        </Text>
                        <Button component={Link} href={`/doctors/${doctor.id}`} variant="light" size="sm" radius="md">
                          View Profile
                        </Button>
                      </Group>
                    </Stack>
                  </Card>
                )
              })}
            </SimpleGrid>

            {doctors.length === 0 && (
              <Stack align="center" py={50}>
                <ThemeIcon size={60} radius="xl" color="gray" variant="light">
                  <IconSearch size={30} />
                </ThemeIcon>
                <Text size="xl" fw={600}>No doctors found</Text>
                <Text c="dimmed">Try adjusting your filters</Text>
              </Stack>
            )}
          </Grid.Col>
        </Grid>
      </Container>
    </Box >
  )
}
