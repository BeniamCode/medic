import {
  Badge,
  Box,
  Button,
  Card,
  Container,
  Divider,
  Grid,
  Group,
  List,
  Paper,
  Stack,
  Tabs,
  Text,
  Textarea,
  ThemeIcon,
  Title,
  Avatar,
  Rating,
  rem,
  SimpleGrid,
  ActionIcon
} from '@mantine/core'
import {
  IconCalendar,
  IconClock,
  IconMapPin,
  IconPhoneCall,
  IconShieldCheck,
  IconVideo,
  IconInfoCircle,
  IconStethoscope,
  IconUser,
  IconMessageCircle,
  IconChevronLeft,
  IconChevronRight
} from '@tabler/icons-react'
import { useState } from 'react'
import { router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'
import { format } from 'date-fns'

export type DoctorProfile = {
  id: string
  fullName: string
  firstName: string
  lastName: string
  title: string | null
  pronouns: string | null
  rating: number | null
  reviewCount: number
  verified: boolean
  profileImageUrl: string | null
  specialty: { name: string; slug: string } | null
  city: string | null
  address: string | null
  hospitalAffiliation: string | null
  yearsOfExperience: number | null
  bio: string | null
  subSpecialties: string[]
  clinicalProcedures: string[]
  conditionsTreated: string[]
  languages: string[]
  awards: string[]
  telemedicineAvailable: boolean
  consultationFee: number | null
  nextAvailableSlot: string | null
}

type AvailabilityDay = {
  date: string
  slots: { startsAt: string; endsAt: string; status: string }[]
}

type PageProps = AppPageProps<{ doctor: DoctorProfile; availability: AvailabilityDay[]; startDate: string }>

const SectionTitle = ({ children, icon: Icon }: { children: React.ReactNode, icon?: any }) => (
  <Group mb="md">
    {Icon && <ThemeIcon variant="light" color="teal"><Icon size={18} /></ThemeIcon>}
    <Title order={3} size="h4">{children}</Title>
  </Group>
)

const APP_LOCALE = 'en-US'

export default function DoctorProfilePage({ doctor, app, auth, availability, startDate }: PageProps) {
  const { t } = useTranslation('default')
  const [selectedDateIndex, setSelectedDateIndex] = useState(0)
  const [selectedSlot, setSelectedSlot] = useState<{ startsAt: string; endsAt: string } | null>(null)
  const [notes, setNotes] = useState('')
  const [appointmentType, setAppointmentType] = useState<'in_person' | 'telemedicine'>(
    doctor.telemedicineAvailable ? 'telemedicine' : 'in_person'
  )
  const [isBooking, setIsBooking] = useState(false)

  const days = availability || []
  const currentDay = days[selectedDateIndex]

  // Pagination Logic
  const currentStart = startDate ? new Date(startDate) : new Date()

  const handleNextWeek = () => {
    const nextDate = new Date(currentStart)
    nextDate.setDate(nextDate.getDate() + 7)
    router.visit(`/doctors/${doctor.id}?date=${format(nextDate, 'yyyy-MM-dd')}`, {
      preserveScroll: true,
      only: ['availability', 'startDate']
    })
    setSelectedDateIndex(0)
    setSelectedSlot(null)
  }

  const handlePrevWeek = () => {
    const prevDate = new Date(currentStart)
    prevDate.setDate(prevDate.getDate() - 7)
    const today = new Date()
    today.setHours(0, 0, 0, 0)
    if (prevDate < today) prevDate.setTime(today.getTime())

    router.visit(`/doctors/${doctor.id}?date=${format(prevDate, 'yyyy-MM-dd')}`, {
      preserveScroll: true,
      only: ['availability', 'startDate']
    })
    setSelectedDateIndex(0)
    setSelectedSlot(null)
  }

  const canGoBack = currentStart > new Date(new Date().setHours(0, 0, 0, 0))


  const handleBook = () => {
    if (!selectedSlot || isBooking) return
    if (!auth.authenticated) {
      router.visit('/login')
      return
    }

    router.post(`/doctors/${doctor.id}/book`, {
      booking: {
        starts_at: selectedSlot.startsAt,
        ends_at: selectedSlot.endsAt,
        appointment_type: appointmentType,
        notes
      }
    }, {
      onStart: () => setIsBooking(true),
      onFinish: () => setIsBooking(false)
    })
  }

  return (
    <Container size="lg" py="xl">
      {/* Profile Header */}
      <Paper radius="md" p={30} mb={40} withBorder bg="white">
        <Group align="flex-start" wrap="nowrap">
          <Avatar
            src={doctor.profileImageUrl}
            size={120}
            radius="md"
            color="teal"
            name={doctor.fullName}
          >
            {doctor.firstName?.[0]}
          </Avatar>

          <Stack gap={4} style={{ flex: 1 }}>
            <Group justify="space-between" align="flex-start">
              <div>
                <Group gap="xs" align="center" mb={4}>
                  <Title order={2}>{doctor.title || 'Dr.'} {doctor.fullName}</Title>
                  {doctor.verified && (
                    <Badge variant="light" color="teal" leftSection={<IconShieldCheck size={12} />}>Verified</Badge>
                  )}
                </Group>
                <Text size="lg" c="dimmed" fw={500}>{doctor.specialty?.name || 'Medical Specialist'}</Text>
              </div>

              <Stack gap={0} align="flex-end">
                <Text c="dimmed" size="xs" tt="uppercase" fw={700}>Consultation</Text>
                <Text size="xl" fw={700} c="teal">
                  {doctor.consultationFee ? `€${doctor.consultationFee}` : 'Ask'}
                </Text>
              </Stack>
            </Group>

            <Group mt="md" gap="xl">
              <Group gap={6}>
                <IconMapPin size={18} style={{ opacity: 0.5 }} />
                <Text>{doctor.city}</Text>
              </Group>
              <Group gap={6}>
                <Rating value={doctor.rating || 0} readOnly size="sm" />
                <Text fw={600} size="sm">{doctor.rating?.toFixed(1)}</Text>
                <Text c="dimmed" size="sm">({doctor.reviewCount} reviews)</Text>
              </Group>
              {doctor.yearsOfExperience && (
                <Group gap={6}>
                  <IconStethoscope size={18} style={{ opacity: 0.5 }} />
                  <Text size="sm">{doctor.yearsOfExperience}+ Years Exp.</Text>
                </Group>
              )}
            </Group>
          </Stack>
        </Group>
      </Paper>

      <Grid gutter={40}>
        <Grid.Col span={12}>

          {/* Centralized Booking Section */}
          <Paper withBorder p="xl" radius="md" mb={50} id="book-appointment" shadow="sm">
            <Stack gap="lg">
              <Group justify="space-between">
                <Title order={3}>Book Appointment</Title>
                {doctor.telemedicineAvailable && (
                  <Group>
                    <Button
                      size="xs"
                      variant={appointmentType === 'in_person' ? 'filled' : 'default'}
                      onClick={() => setAppointmentType('in_person')}
                      leftSection={<IconMapPin size={14} />}
                    >
                      Clinic Visit
                    </Button>
                    <Button
                      size="xs"
                      variant={appointmentType === 'telemedicine' ? 'filled' : 'default'}
                      onClick={() => setAppointmentType('telemedicine')}
                      leftSection={<IconVideo size={14} />}
                    >
                      Video Call
                    </Button>
                  </Group>
                )}
              </Group>

              <Divider />

              <Box>
                <Group justify="space-between" mb="sm">
                  <Text fw={600}>Select Date</Text>
                  <Group gap={6}>
                    <ActionIcon variant="default" size="lg" disabled={!canGoBack} onClick={handlePrevWeek}>
                      <IconChevronLeft size={16} />
                    </ActionIcon>
                    <Text size="sm" fw={500}>{format(currentStart, 'MMMM yyyy')}</Text>
                    <ActionIcon variant="default" size="lg" onClick={handleNextWeek}>
                      <IconChevronRight size={16} />
                    </ActionIcon>
                  </Group>
                </Group>

                <Group gap="xs" wrap="nowrap" style={{ overflowX: 'auto', paddingBottom: 4 }}>
                  {days.map((day: AvailabilityDay, index: number) => {
                    const isSelected = selectedDateIndex === index
                    const d = new Date(day.date)
                    return (
                      <Paper
                        key={day.date}
                        withBorder={!isSelected}
                        bg={isSelected ? 'teal.0' : 'white'}
                        style={{ borderColor: isSelected ? 'var(--mantine-color-teal-5)' : undefined, cursor: 'pointer', minWidth: 80 }}
                        p="xs"
                        radius="md"
                        onClick={() => { setSelectedDateIndex(index); setSelectedSlot(null); }}
                        className="transition-all hover:shadow-sm"
                      >
                        <Stack gap={0} align="center">
                          <Text size="xs" c={isSelected ? 'teal' : 'dimmed'} tt="uppercase" fw={700}>{d.toLocaleDateString(APP_LOCALE, { weekday: 'short' })}</Text>
                          <Text fw={700} size="lg" c={isSelected ? 'teal' : 'dark'}>{d.getDate()}</Text>
                        </Stack>
                      </Paper>
                    )
                  })}
                </Group>
              </Box>

              <Box>
                <Text fw={600} mb="sm">Available Slots</Text>
                {currentDay?.slots?.filter((s: any) => s.status === 'free').length > 0 ? (
                  <SimpleGrid cols={{ base: 3, sm: 4, md: 5 }} spacing="sm">
                    {currentDay.slots
                      .filter((slot: any) => slot.status === 'free')
                      .map((slot: any) => (
                        <Button
                          key={slot.startsAt}
                          variant={selectedSlot?.startsAt === slot.startsAt ? 'filled' : 'outline'}
                          onClick={() => setSelectedSlot(slot)}
                          color="teal"
                          radius="md"
                        >
                          {new Date(slot.startsAt).toLocaleTimeString(APP_LOCALE, { hour: '2-digit', minute: '2-digit' })}
                        </Button>
                      ))
                    }
                  </SimpleGrid>
                ) : (
                  <Paper bg="gray.0" p="md" radius="md">
                    <Text c="dimmed" size="sm" ta="center">No available slots for this date.</Text>
                  </Paper>
                )}
              </Box>

              {selectedSlot && (
                <>
                  <Textarea
                    placeholder="Reason for visit (optional)..."
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    minRows={2}
                    variant="filled"
                    disabled={isBooking}
                  />

                  <Button
                    size="lg"
                    fullWidth
                    onClick={handleBook}
                    color="teal"
                    disabled={!selectedSlot || isBooking}
                    loading={isBooking}
                  >
                    Confirm Booking
                  </Button>
                  <Text size="xs" c="dimmed" ta="center">No payment required to book.</Text>
                </>
              )}
            </Stack>
          </Paper>

          {/* Details Tabs */}
          <Tabs defaultValue="about" color="teal" radius="md">
            <Tabs.List mb="xl">
              <Tabs.Tab value="about" leftSection={<IconUser size={16} />}>About & Expertise</Tabs.Tab>
              <Tabs.Tab value="location" leftSection={<IconMapPin size={16} />}>Location</Tabs.Tab>
              <Tabs.Tab value="reviews" leftSection={<IconMessageCircle size={16} />}>Reviews ({doctor.reviewCount})</Tabs.Tab>
            </Tabs.List>

            <Tabs.Panel value="about">
              <Grid gutter={40}>
                <Grid.Col span={{ base: 12, md: 8 }}>
                  <Box mb={40}>
                    <Title order={4} mb="md">Biography</Title>
                    <Text lh={1.7} c="gray.7">{doctor.bio || "No biography available."}</Text>
                  </Box>

                  {(doctor.clinicalProcedures.length > 0 || doctor.conditionsTreated.length > 0) && (
                    <Box>
                      <Title order={4} mb="md">Medical Expertise</Title>
                      <SimpleGrid cols={{ base: 1, sm: 2 }} spacing="xl">
                        <Box>
                          <Text fw={600} mb="sm" size="sm" c="dimmed" tt="uppercase">Procedures</Text>
                          <List spacing="xs" size="sm" center icon={<ThemeIcon color="teal.1" c="teal.6" size={16} radius="xl"><IconStethoscope size={10} /></ThemeIcon>}>
                            {doctor.clinicalProcedures.slice(0, 5).map(p => <List.Item key={p}>{p}</List.Item>)}
                          </List>
                        </Box>
                        <Box>
                          <Text fw={600} mb="sm" size="sm" c="dimmed" tt="uppercase">Conditions Treated</Text>
                          <List spacing="xs" size="sm" center icon={<ThemeIcon color="teal.1" c="teal.6" size={16} radius="xl"><IconStethoscope size={10} /></ThemeIcon>}>
                            {doctor.conditionsTreated.slice(0, 5).map(c => <List.Item key={c}>{c}</List.Item>)}
                          </List>
                        </Box>
                      </SimpleGrid>
                    </Box>
                  )}
                </Grid.Col>
                {/* Side Info in About Tab */}
                <Grid.Col span={{ base: 12, md: 4 }}>
                  {doctor.subSpecialties.length > 0 && (
                    <Paper withBorder p="lg" radius="md">
                      <Text fw={600} mb="md">Special Interests</Text>
                      <Group gap="xs">
                        {doctor.subSpecialties.map(s => <Badge key={s} variant="light" color="gray">{s}</Badge>)}
                      </Group>
                    </Paper>
                  )}
                </Grid.Col>
              </Grid>
            </Tabs.Panel>

            <Tabs.Panel value="location">
              <Grid gutter={40}>
                <Grid.Col span={{ base: 12, md: 4 }}>
                  <Box mb={20}>
                    <Title order={4} mb="sm">Practice Address</Title>
                    <Text size="lg" fw={500}>{doctor.address}</Text>
                    <Text c="dimmed">{doctor.city}</Text>
                  </Box>

                  {doctor.hospitalAffiliation && (
                    <Box>
                      <Text fw={600} size="sm" c="dimmed" tt="uppercase">Affiliation</Text>
                      <Text>{doctor.hospitalAffiliation}</Text>
                    </Box>
                  )}
                </Grid.Col>
                <Grid.Col span={{ base: 12, md: 8 }}>
                  <Paper h={400} bg="gray.1" radius="md" style={{ overflow: 'hidden' }}>
                    {/* Future Map Component */}
                    <Stack align="center" justify="center" h="100%" c="dimmed" gap={4}>
                      <IconMapPin size={32} />
                      <Text>Interactive Map</Text>
                      <Button variant="subtle" size="xs">Get Directions</Button>
                    </Stack>
                  </Paper>
                </Grid.Col>
              </Grid>
            </Tabs.Panel>

            <Tabs.Panel value="reviews">
              <Container size="sm" p={0}>
                <Stack gap="xl">
                  <Paper p="xl" withBorder radius="md" bg="gray.0">
                    <Stack align="center">
                      <Text fw={700} size="xl">Patient Reviews</Text>
                      <Text c="dimmed">Verified patient feedback for Dr. {doctor.lastName} will appear here.</Text>
                    </Stack>
                  </Paper>
                </Stack>
              </Container>
            </Tabs.Panel>
          </Tabs>
        </Grid.Col>
      </Grid>
    </Container>
  )
}
