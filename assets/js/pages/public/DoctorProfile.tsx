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
  SimpleGrid
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
  IconMessageCircle
} from '@tabler/icons-react'
import { useState } from 'react'
import { router } from '@inertiajs/react'
import { useTranslation } from 'react-i18next'
import type { AppPageProps } from '@/types/app'

export type DoctorProfile = {
  id: string
  full_name: string
  first_name: string
  last_name: string
  title: string | null
  pronouns: string | null
  rating: number | null
  review_count: number
  verified: boolean
  profile_image_url: string | null
  specialty: { name: string; slug: string } | null
  city: string | null
  address: string | null
  hospital_affiliation: string | null
  years_of_experience: number | null
  bio: string | null
  sub_specialties: string[]
  clinical_procedures: string[]
  conditions_treated: string[]
  languages: string[]
  awards: string[]
  telemedicine_available: boolean
  consultation_fee: number | null
  next_available_slot: string | null
}

type AvailabilityDay = {
  date: string
  slots: { starts_at: string; ends_at: string; status: string }[]
}

type PageProps = AppPageProps<{ doctor: DoctorProfile; availability: AvailabilityDay[] }>

const SectionTitle = ({ children, icon: Icon }: { children: React.ReactNode, icon?: any }) => (
  <Group mb="md">
    {Icon && <ThemeIcon variant="light" color="teal"><Icon size={18} /></ThemeIcon>}
    <Title order={3} size="h4">{children}</Title>
  </Group>
)

export default function DoctorProfilePage({ doctor, app, auth, availability }: PageProps) {
  const { t } = useTranslation('default')
  const [selectedDateIndex, setSelectedDateIndex] = useState(0)
  const [selectedSlot, setSelectedSlot] = useState<{ starts_at: string; ends_at: string } | null>(null)
  const [notes, setNotes] = useState('')
  const [appointmentType, setAppointmentType] = useState<'in_person' | 'telemedicine'>(
    doctor.telemedicine_available ? 'in_person' : 'in_person'
  )

  const days = availability || []
  const currentDay = days[selectedDateIndex]

  const handleBook = () => {
    if (!selectedSlot) return
    if (!auth.authenticated) {
      router.visit('/login')
      return
    }

    router.post(`/doctors/${doctor.id}/book`, {
      booking: {
        starts_at: selectedSlot.starts_at,
        ends_at: selectedSlot.ends_at,
        appointment_type: appointmentType,
        notes
      }
    })
  }

  return (
    <Container size="xl" py="xl">
      {/* Profile Header */}
      <Card withBorder padding="xl" radius="lg" mb={40} shadow="sm">
        <Grid align="center" gutter="xl">
          <Grid.Col span={{ base: 12, sm: 'content' }}>
            <Avatar
              src={doctor.profile_image_url}
              size={160}
              radius="md"
              color="teal"
            >
              {doctor.first_name[0]}
            </Avatar>
          </Grid.Col>
          <Grid.Col span={{ base: 12, sm: 'auto' }}>
            <Stack gap="xs">
              <Group>
                <Title order={1}>{doctor.title || 'Dr.'} {doctor.full_name}</Title>
                {doctor.verified && (
                  <Badge size="lg" color="teal" variant="light" leftSection={<IconShieldCheck size={14} />}>Verified</Badge>
                )}
              </Group>

              <Text size="lg" fw={500} c="dimmed">
                {doctor.specialty?.name || 'General Practitioner'}
                {doctor.hospital_affiliation && ` • ${doctor.hospital_affiliation}`}
              </Text>

              <Group gap="lg" mt="sm">
                <Group gap={6}>
                  <IconMapPin size={18} className="text-gray-500" />
                  <Text>{doctor.city}</Text>
                </Group>
                <Group gap={6}>
                  <Rating value={doctor.rating || 0} readOnly />
                  <Text fw={600}>{doctor.rating?.toFixed(1)}</Text>
                  <Text c="dimmed">({doctor.review_count} reviews)</Text>
                </Group>
                {doctor.years_of_experience && (
                  <Group gap={6}>
                    <IconStethoscope size={18} className="text-gray-500" />
                    <Text>{doctor.years_of_experience}+ Years Exp.</Text>
                  </Group>
                )}
              </Group>
            </Stack>
          </Grid.Col>
          <Grid.Col span={{ base: 12, md: 3 }} style={{ display: 'flex', justifyContent: 'flex-end' }}>
            <Card bg="teal.0" radius="md" p="lg" w="100%">
              <Stack gap="xs" align="center">
                <Text c="dimmed" size="xs" tt="uppercase" fw={700}>Consultation Fee</Text>
                <Text size={rem(32)} fw={700} c="teal" lh={1}>
                  {doctor.consultation_fee ? `€${doctor.consultation_fee}` : 'Ask'}
                </Text>
                {doctor.telemedicine_available && (
                  <Badge color="blue" variant="dot">Video Available</Badge>
                )}
              </Stack>
            </Card>
          </Grid.Col>
        </Grid>
      </Card>

      <Grid gutter={40}>
        <Grid.Col span={{ base: 12, md: 8 }}>
          <Tabs defaultValue="about" radius="md" color="teal">
            <Tabs.List mb="xl">
              <Tabs.Tab value="about" leftSection={<IconUser size={16} />}>About</Tabs.Tab>
              <Tabs.Tab value="location" leftSection={<IconMapPin size={16} />}>Location</Tabs.Tab>
              <Tabs.Tab value="reviews" leftSection={<IconMessageCircle size={16} />}>Reviews</Tabs.Tab>
            </Tabs.List>

            <Tabs.Panel value="about">
              <Stack gap="xl">
                <Box>
                  <SectionTitle icon={IconInfoCircle}>Biography</SectionTitle>
                  <Text lh={1.6}>{doctor.bio || "No biography available."}</Text>
                </Box>

                <Divider />

                {doctor.sub_specialties.length > 0 && (
                  <Box>
                    <SectionTitle icon={IconStethoscope}>Special Interests</SectionTitle>
                    <Group gap="xs">
                      {doctor.sub_specialties.map(s => <Badge key={s} size="lg" variant="outline" color="gray">{s}</Badge>)}
                    </Group>
                  </Box>
                )}

                {(doctor.clinical_procedures.length > 0 || doctor.conditions_treated.length > 0) && (
                  <Grid>
                    <Grid.Col span={6}>
                      <SectionTitle>Procedures</SectionTitle>
                      <List spacing="xs" size="sm" center icon={<ThemeIcon color="teal" size={6} radius="xl"><IconStethoscope size={0} /></ThemeIcon>}>
                        {doctor.clinical_procedures.map(p => <List.Item key={p}>{p}</List.Item>)}
                      </List>
                    </Grid.Col>
                    <Grid.Col span={6}>
                      <SectionTitle>Conditions</SectionTitle>
                      <List spacing="xs" size="sm" center icon={<ThemeIcon color="teal" size={6} radius="xl"><IconStethoscope size={0} /></ThemeIcon>}>
                        {doctor.conditions_treated.map(c => <List.Item key={c}>{c}</List.Item>)}
                      </List>
                    </Grid.Col>
                  </Grid>
                )}
              </Stack>
            </Tabs.Panel>

            <Tabs.Panel value="location">
              <Stack>
                <SectionTitle icon={IconMapPin}>Practice Location</SectionTitle>
                <Text size="lg">{doctor.address}, {doctor.city}</Text>
                <Paper h={400} bg="gray.1" withBorder radius="md">
                  {/* Map Implementation Placeholder */}
                  <Stack align="center" justify="center" h="100%" c="dimmed">
                    <IconMapPin size={40} />
                    <Text>Map View</Text>
                  </Stack>
                </Paper>
              </Stack>
            </Tabs.Panel>

            <Tabs.Panel value="reviews">
              <Stack align="center" py="xl">
                <Text c="dimmed">Reviews coming soon...</Text>
              </Stack>
            </Tabs.Panel>
          </Tabs>
        </Grid.Col>

        <Grid.Col span={{ base: 12, md: 4 }}>
          <Stack style={{ position: 'sticky', top: 20 }}>
            <Card shadow="sm" radius="lg" padding="xl" withBorder>
              <Stack gap="lg">
                <Title order={3} size="h4">{t('doctor.booking.title', 'Book Appointment')}</Title>

                {doctor.telemedicine_available && (
                  <Grid gutter="xs">
                    <Grid.Col span={6}>
                      <Button
                        variant={appointmentType === 'in_person' ? 'filled' : 'light'}
                        fullWidth
                        onClick={() => setAppointmentType('in_person')}
                        leftSection={<IconMapPin size={16} />}
                      >
                        Clinic
                      </Button>
                    </Grid.Col>
                    <Grid.Col span={6}>
                      <Button
                        variant={appointmentType === 'telemedicine' ? 'filled' : 'light'}
                        fullWidth
                        onClick={() => setAppointmentType('telemedicine')}
                        leftSection={<IconVideo size={16} />}
                      >
                        Video
                      </Button>
                    </Grid.Col>
                  </Grid>
                )}

                {/* Date Selection */}
                <Box>
                  <Text fw={600} mb="xs">Select Date</Text>
                  <Group gap="xs">
                    {days.map((day, index) => (
                      <Button
                        key={day.date}
                        variant={selectedDateIndex === index ? 'light' : 'default'}
                        onClick={() => { setSelectedDateIndex(index); setSelectedSlot(null); }}
                        size="compact-sm"
                      >
                        {new Date(day.date).toLocaleDateString(APP_LOCALE, { weekday: 'short', day: 'numeric' })}
                      </Button>
                    ))}
                  </Group>
                </Box>

                <Divider />

                {/* Slot Selection */}
                <Box>
                  <Text fw={600} mb="xs">Available Slots</Text>
                  {currentDay?.slots?.length > 0 ? (
                    <SimpleGrid cols={3} spacing="xs">
                      {currentDay.slots
                        .filter(slot => slot.status === 'free')
                        .map(slot => (
                          <Button
                            key={slot.starts_at}
                            variant={selectedSlot?.starts_at === slot.starts_at ? 'filled' : 'outline'}
                            size="xs"
                            onClick={() => setSelectedSlot(slot)}
                            color="teal"
                          >
                            {new Date(slot.starts_at).toLocaleTimeString(APP_LOCALE, { hour: '2-digit', minute: '2-digit' })}
                          </Button>
                        ))
                      }
                    </SimpleGrid>
                  ) : (
                    <Text c="dimmed" size="sm">No slots available for this day.</Text>
                  )}
                </Box>

                <Textarea
                  placeholder="Reason for visit..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  minRows={3}
                />

                <Button size="lg" fullWidth onClick={handleBook} disabled={!selectedSlot}>
                  Confirm Booking
                </Button>

                <Text size="xs" c="dimmed" ta="center">
                  No payment required to book.
                </Text>
              </Stack>
            </Card>
          </Stack>
        </Grid.Col>
      </Grid>
    </Container>
  )
}

// Temporary constant until we pull from app props
const APP_LOCALE = 'en-US'
